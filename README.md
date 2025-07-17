


 ### *A suite of lightweight shell scripts providing hardware control for ChromeOS.*
 <br>
 <br>
 
<p align="center">
  <img src="https://i.imgur.com/uELNNt2.png" alt="logo" width="300" />
</p>  

<p align="center">
  <img src="https://i.imgur.com/fh8dBwa.png" alt="logo" />
</p>

  <br> <br>
- Can use global commands for ease of use, has a unified config file, and the ability to change settings in real-time. 
- Contains a feature-rich installer, an uninstaller that cleans up after itself, and logs stored in /var/log/ for statistics.
- Optionally have BatteryControl, PowerControl, FanControl, GPUControl, and SleepControl start on boot if user has rootfs verification disabled.
- Requires Developer Mode - Supports AMD, ARM, and Intel.


<br> <br> 







### __How to Install:__

- Open crosh shell and run: <br>

 `bash <(curl -s "https://raw.githubusercontent.com/shadowed1/ChromeOS_PowerControl/unstable/ChromeOS_PowerControl_Downloader.sh?$(date +%s)")`

- The installer will be placed: <br>

  `/home/chronos/ChromeOS_PowerControl/ChromeOS_PowerControl_Installer.sh`

- In *VT-2* or *crosh shell with sudo enabled* run:

 `sudo mkdir -p /usr/local/bin` <br>
 `sudo mv /home/chronos/ChromeOS_PowerControl_Installer.sh /usr/local/bin` <br>
 `sudo bash /usr/local/bin/ChromeOS_PowerControl_Installer.sh`

- Installer has prompts to customize installation.
- PowerControl, BatteryControl, FanControl, and SleepControl can run in the background and can be adjusted in real-time.
<br> <br>


<p align="center">
  <img src="https://i.imgur.com/JK3K8og.png" alt="logo" />
</p>

<p align="center">
  <img src="https://i.imgur.com/ghKV55q.png" alt="logo" />
</p>

<p align="center">
  <img src="https://i.imgur.com/UGKgbqw.png" alt="logo" />
</p>

<p align="center">
  <img src="https://i.imgur.com/Z8aRKd9.png" alt="logo" />
</p>

<p align="center">
  <img src="https://i.imgur.com/Rq5D4BV.png" alt="logo" />
</p>



    
<br> <br>

__How It Works:__

<br>

*PowerControl:*

- Uses ARM, AMD, and Intel's max_perf_pct for easy user control.
- Pairs user adjustable max_perf_pct and thermal0 temp sensor to create a user adjustable clockspeed-temperature curve. 
- If $min_temp threshold is below a certain point, the CPU will be able to reach max_perf_pct of its speed.
- The closer the CPU approaches $max_temp, the closer it is to min_perf_pct.
- PowerControl will always be stringent regarding thermals and performance versus native behavior.

<br>

*BatteryControl:*

- Uses ectool's chargecontrol to toggle between normal or idle.
- Check's ectool usbpdpower to identify which charge port is being used
- Recommend turning off adatpive charging in ChromeOS to avoid notification spam.
- Check's BAT0/capacity to measure when to toggle ectool's chargecontrol.
- ChromeOS reports slightly higher values than what BatteryControl sets the charge limit to.
- Charge limit is preserved during sleep unless in deep sleep before reaching limit.

<br>

*FanControl:*

- Uses ectool's fanduty control and autofanctrl for manual and automatic control.
- Pairs fanduty with thermal0 temperature sensor for a user adjustable fan-temperature curve.
- Uses hysteresis formula to attempt a better sounding and performing fan curve than the OEM provides. 
- Uses a kickstart mechanism when fan leaves 0% to enable zero RPM mode for any fan type.
- Default FanControl behavior has aggressive fan ramp-up behavior with a graceful decrease.

<br>

*GPUControl:*

- Identifies the GPU (AMD, Adreno, Mali, and Intel) based on the name of the device's path in /sys/class/
- Limits control to only below the maximum clock speed for safety and with Chromebooks in mind.
- Applies a 120s delay on boot if the user is applying a custom clock speed as a precaution.
- Intel GPU's maximum clock speed changed from: /sys/class/drm/card0/gt_max_freq_mhz
- AMD GPU's maximum clockspeed changed from: /sys/class/drm/card0/pp_od_clk_voltage
- Adreno GPU's maximum clockspeed changed from /sys/class/kgsl/kgsl-3d0/max_gpuclk
- Mali GPU's maximum clockspeed changed from: /sys/class/devfreq/mali0/max_freq

<br>


*SleepControl:*

- By reading powerd.LATEST log, SleepControl monitors when the powerd daemon reports 'User activity stopped'.
- Parsing strings like 'User activity started' or 'Audio activity started' tells SleepControl the user is active. to pause until  is reported.
- If 'User activity stopped' and 'Audio activity stopped' is parsed, SleepControl assumes the user is away and custom sleep timers can begin.
- Can turn on or off audio detection to customize sleep during multimedia playback.
- ChromeOS will report 'User activity stopped' after around 20 seconds of inactivity, so the timers won't be exact.
- When idle, SleepControl uses dbus to send an empty input every 120s until interrupted/sleeping with the configurable timer.  
- By using epoch timestamps, SleepControl is able to check when its simulated inputs are to be ignored.
<br>

__Bonus:__
- To disable rootfs verification and enable sudo in crosh try out sudoCrosh: https://github.com/shadowed1/sudoCrosh/ 
<pre>bash <(curl -s "https://raw.githubusercontent.com/shadowed1/sudoCrosh/main/sudocrosh_downloader.sh?$(date +%s)")</pre>

<br>

*Changelog:*

- 0.1:  `Released BatteryControl.`<br> <br>
- 0.11: `Released PowerControl with CPU performance curve and combined BatteryControl.`<br> <br>
- 0.12: `Added support for AMD and ARM.`<br> <br>
- 0.13: `Added FanControl.`<br> <br>
- 0.14: `Updated BatteryControl to support switching charging ports.`<br> <br>
- 0.15: `Updated UI, added customizing install location, merged config files into one, and added commands.`<br> <br>
- 0.16: `Fixed several syntax errors and improved color coding.`<br> <br>
- 0.17: `Added GPUControl, cleaned up useless code, improved logs, config settings preserved on reinstalling, and fixed syntax errors.`<br> <br>
- 0.18: `Added gpucontrol restore command. Added ability to boot up with desired GPU clockspeed with 120s delay.
AMD GPU support tweaked to allow idle clocks when overriding clockspeed. Added reinstall command for fast updating.
Uninstaller no longer requiring user to reboot to restore GPU clockspeed. Fixed duplicate log entry and other bugs.
Added ramp_up and ramp_down commands for PowerControl CPU scaling speed.
Added stop processes commands and better cleanup when running startup, reinstalling and uninstalling.
Reformatted status for better readability. Added post-install notes for BatteryControl and GPUControl.`<br><br>
- 0.19: `Added SleepControl - control how long ChromeOS can remain idle before sleeping; irrespective of system sleep settings.
Removed Intel Turbo Boost questions from installer but keeping the options to toggle in PowerControl.`<br><br>
- 0.20: `Added dimming feature for SleepControl. Fixed SleepControl not switching between power and battery modes. Fixed some minor typos.
Added delay on startup for SleepControl. Improved audio detection for sleep prevention.`<br><br>
- 0.21: `Added commands for SleepControl to toggle audio detection for battery and power.`<br><br>
- 0.22: `PowerControl gets HOTZONE variable - Allowing non-linear performance scaling until hotzone threshold is reached.
FanControl hysteresis formula improved by adding gradual ramping with asymmetric steps.
BatteryControl simplified; no need to manage $CHARGE_MIN and removed requirement for 'set' argument.` <br><br>
- 0.23: `Improved Hotzone scaling math to be more thermally proactive.
Fixed FanControl from not fully disabling autofanctrl on boot for the first minute or so.`<br><br>
- 0.24: `Changed variable for input to choice then checked if it's populated, else use existing value for INSTALL_DIR.
Added checking versions for latest available and offering reinstall option if it's not up-to-date.
Thanks to DennisLfromGA for implementing these changes.` <br><br>
- 0.25: `Simplified file structure thanks to DennyL's crouton upstart script from 2014. Improved version checking thanks to DennyL. 
Reworked FanControl zero RPM ramp to be more gradual. Improve step-up and step-down algorithm. Renamed fancontrol update command.
Added PowerControl polling command. Made UI more organized.` <br><br>
- 0.26: `Passively cooled device awareness added for FanControl and the installer. 
Added message to make sure sudo is run for commands (excluding status and help).
Thanks again to DennyL for the suggestions!`
- 0.27: `Fixed bug with SleepControl not starting on boot.` <br> <br>
- 0.28: `Fixed bug with GPUControl not applying user-preferred clockspeed on boot and refactored sections. Fixed version script for supporting base 10 values.` <br><br>
__Acknowledgements:__

- Thanks to WesBosch for helping me learn to make an installer:
  https://github.com/WesBosch
  
- Thanks to DennisLfromGA for showing me how to enable sudo on crosh, testing out PowerControl, finding bugs, implementing fixes, and providing  many great suggestions:
https://github.com/DennisLfromGA

