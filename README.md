


<p align="center">
  <img src="https://i.imgur.com/RbK8dR6.png" alt="logo" />
</p>  
<br> <br>
ChromeOS_PowerControl is a suite of lightweight shell scripts.
  <br> <br>

- *PowerControl:* Control CPU clockspeed in relation to temperature; enabling lower temperatures and longer battery life under load.<br>
- *BatteryControl:* Control battery charging limit instead of relying on Adaptive Charging to maximize battery longevity.<br>
- *FanControl:* Control fan curve in relation to temperature with built-in hysteresis and 0% RPM mode.<br>
- *GPUControl:* Control GPU clockspeed below its default maximum; enabling longer battery life under load.<br>
- *SleepControl:* Control how long ChromeOS can remain idle before sleep; with display dimming support.<br>
  <br> <br>
- Features global commands for ease of use, a unified config file, and the ability to change settings in real-time. 
- Has a feature-rich installer, an uninstaller that cleans up after itself, and logs stored in /var/log/ for statistics.
- Optionally have BatteryControl, PowerControl, FanControl, GPUControl, and SleepControl start on boot; as well as disabling Intel Turbo Boost automatically if user has rootfs verification disabled.
<br> <br> <br>


__Requires Developer Mode - Supports AMD, ARM, and Intel.__
<br><br>

__How to Install:__

- Open crosh shell and run: <br>

 `bash <(curl -s "https://raw.githubusercontent.com/shadowed1/ChromeOS_PowerControl/main/ChromeOS_PowerControl_Downloader.sh?$(date +%s)")`

- The installer will be placed: <br>

  `/home/chronos/ChromeOS_PowerControl/ChromeOS_PowerControl_Installer.sh`

- In *VT-2* or *crosh shell with sudo enabled* run:

 `sudo mkdir -p /usr/local/bin` <br>
 `sudo mv /home/chronos/ChromeOS_PowerControl_Installer.sh /usr/local/bin` <br>
 `sudo bash /usr/local/bin/ChromeOS_PowerControl_Installer.sh`

- Installer has prompts to customize installation.
- PowerControl, BatteryControl, and FanControl can run in the background and can be adjusted in real-time.
<br> <br> <br>

__Commands with examples:__
<br>

*PowerControl:*

`sudo powercontrol                     # Show status`<br>
`sudo powercontrol start               # Throttle CPU based on temperature curve`<br>
`sudo powercontrol stop                # Restore default CPU settings`<br>
`sudo powercontrol no_turbo 1          # 0 = Enable, 1 = Disable Turbo Boost`<br>
`sudo powercontrol max_perf_pct 75     # Set max performance percentage`<br>
`sudo powercontrol min_perf_pct 50     # Set minimum performance at max temp`<br>
`sudo powercontrol max_temp 86         # Max temperature threshold - Limit is 90 C`<br>
`sudo powercontrol min_temp 60         # Min temperature threshold`<br>
`sudo powercontrol ramp_up 15          # % in steps CPU will increase in clockspeed per second` <br>
`sudo powercontrol ramp_down 20        # % in steps CPU will decrease in clockspeed per second` <br>
`sudo powercontrol monitor             # Toggle live temperature monitoring`<br>
`sudo powercontrol startup             # Copy/Remove no_turbo.conf & powercontrol.conf at: /etc/init/`<br>
`sudo powercontrol version             # Check PowerControl version`<br>
`sudo powercontrol help                # Help menu`<br>
  
----------------------------------------------------------------------------------------------

*BatteryControl:*

`sudo batterycontrol                   # Check BatteryControl status`<br>
`sudo batterycontrol start             # Start BatteryControl`<br>
`sudo batterycontrol stop              # Stop BatteryControl`<br>
`sudo batterycontrol set 77 74         # Set max/min battery charge thresholds`<br>
`sudo batterycontrol startup           # Copy/Remove batterycontrol.conf at: /etc/init/`<br>
`sudo batterycontrol help              # Help menu`<br>

----------------------------------------------------------------------------------------------

*FanControl:*

`sudo fancontrol                       # Show FanControl status`<br>
`sudo fancontrol start                 # Start FanControl`<br>
`sudo fancontrol stop                  # Stop FanControl`<br>
`sudo fancontrol fan_min_temp 48       # Min temp threshold`<br>
`sudo fancontrol fan_max_temp 81       # Max temp threshold - Limit is 90 C`<br>
`sudo fancontrol min_fan 0             # Min fan speed %`<br>
`sudo fancontrol max_fan 100           # Max fan speed %`<br>
`sudo fancontrol stepup 20             # Fan step-up %`<br>
`sudo fancontrol stepdown 1            # Fan step-down %`<br>
`sudo fancontrol monitor               # Toggle on/off live monitoring in terminal`<br>
`sudo fancontrol startup               # Copy/Remove fancontrol.conf at: /etc/init/`<br>
`sudo fancontrol help                  # Help menu`<br>

----------------------------------------------------------------------------------------------

*GPUControl:*

`sudo gpucontrol                        # Show current GPU info and frequency`<br>
`sudo gpucontrol restore                # Restore GPU max frequency to original value`<br>
`sudo gpucontrol intel 700              # Clamp Intel GPU max frequency to 700 MHz`<br>
`sudo gpucontrol amd 800                # Clamp AMD GPU max frequency to 800 MHz (rounds down)`<br>
`sudo gpucontrol adreno 500000          # Clamp Adreno GPU max frequency to 500000 kHz (or 500 MHz)`<br>
`sudo gpucontrol mali 600000            # Clamp Mali GPU max frequency to 600000 kHz (or 600 MHz)`<br>
`sudo gpucontrol startup                # Copy/Remove gpucontrol.conf at: /etc/init/`<br>
`sudo gpucontrol help                   # Help menu`<br>

----------------------------------------------------------------------------------------------

*SleepControl:*


`sudo sleepcontrol                     # Show current GPU info and frequency`<br>
`sudo sleepcontrol start               # Start SleepControl`<br>
`sudo sleepcontrol stop                # Stop SleepControl`<br>
`sudo sleepcontrol battery 3 7 12      # When idle, display dims in 3m, timeout in 7m, and ChromeOS sleeps in 12m when on battery`<br>
`sudo sleepcontrol power 5 15 30       # When idle, display dims in 5m, timeout in 15m and ChromeOS sleeps in 30m when on plugged-in`<br>
`sudo sleepcontrol startup             # Copy or Remove sleepcontrol.conf at: /etc/init/`<br>
`sudo sleepcontrol help                # Help menu`<br>


----------------------------------------------------------------------------------------------
*Reinstall:*

`sudo powercontrol reinstall           # Download and reinstall ChromeOS_PowerControl from main branch on Github.`<br>

*Uninstall:*

`sudo powercontrol uninstall            # Global uninstaller that will clean up after itself.`

*Alternative uninstall:* <br>

 `sudo /usr/local/bin/ChromeOS_PowerControl/Uninstall_ChromeOS_PowerControl.sh`

 ----------------------------------------------------------------------------------------------
 
<br> 

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
- Charge limit is preserved during sleep. 

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
- Parsing strings like 'User activity started' or 'Audio activity' tells SleepControl to pause until 'User activity stopped' is reported.
- When idle, SleepControl uses dbus to send an empty input every 120s until interrupted/sleeping with the configurable timer.  
- By using epoch timestamps, SleepControl is able to check when its simulated inputs are to be ignored.
<br>

__Bonus:__
- To disable rootfs verification for /etc/init startup options, open VT-2, login as root, and reboot after running:
 `/usr/libexec/debugd/helpers/dev_features_rootfs_verification` 
- Enable sudo for crosh: `https://gist.github.com/velzie/a5088c9ade6ec4d35435b9826b45d7a3`

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
Removed Intel Turbo Boost questions from installer but keeping the options to toggle in PowerControl.`

<br>

__Credits:__

- Thanks to WesBosch for helping me learn to make an installer:
  https://github.com/WesBosch
  
- Thanks to DennyL on ChromeOS discord for showing me how to enable sudo on crosh, test out PowerControl, and provide many great suggestions. 

