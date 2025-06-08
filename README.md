


<p align="center">
  <img src="https://i.imgur.com/yMQmKrF.png" alt="logo" />
</p>  
<br> <br> <br>

- Requires Developer Mode - Supports AMD, ARM, and Intel. 
- Control battery charging limit instead of relying on Adaptive Charging to maximize battery longevity.
- Control CPU clockspeed in relation to temperature; enabling lower temperatures under load and longer battery life.
- Control fan curve in relation to temperature with built-in hysteresis and 0% RPM mode.
- Features global commands for ease of use, config files that save settings, and an uninstaller to clean up after itself.
- Optionally have BatteryControl, PowerControl, FanControl start on boot; as well as disabling Turbo Boost on boot if user has rootfs verification disabled.
<br> <br> <br>

*How to Install:*

- Open crosh shell and run:

- `bash <(curl -s "https://raw.githubusercontent.com/shadowed1/ChromeOS_PowerControl/beta/ChromeOS_PowerControl_Downloader.sh?$(date +%s)")`

- The installer will be placed: <br> `/home/chronos/ChromeOS_PowerControl/ChromeOS_PowerControl_Installer.sh`

- In *VT-2* or *crosh shell with sudo enabled* run:
  
- `sudo mv ~/tmp/ChromeOS_PowerControl_Installer.sh /usr/local/bin`
- `sudo bash /usr/local/bin/ChromeOS_PowerControl_Installer.sh`

- Installer has prompts to customize installation.
- PowerControl, BatteryControl, and FanControl can run in the background and can be adjusted in real-time.
<br> <br> <br>
Commands with examples:
<br>

*PowerControl:*

`sudo powercontrol                     # Show status"`<br>
`sudo powercontrol start               # Throttle CPU based on temperature curve"`<br>
`sudo powercontrol stop                # Restore default CPU settings"`<br>
`sudo powercontrol no_turbo 1          # Disable turbo boost"`<br>
`sudo powercontrol max_perf_pct 75     # Set max performance percentage"`<br>
`sudo powercontrol min_perf_pct 50     # Set minimum performance at max temp"`<br>
`sudo powercontrol max_temp 86         # Max temperature threshold"`<br>
`sudo powercontrol min_temp 60         # Min temperature threshold"`<br>
`sudo powercontrol monitor             # Live temperature monitoring"`<br>
`sudo powercontrol startup             # Initiate powercontrol /etc/init .conf installer"`<br>
`sudo powercontrol help                # Help menu"`<br>
  
----------------------------------------------------------------------------------------------
<br>

*BatteryControl:*

`sudo batterycontrol                   # Check BatteryControl status"`<br>
`sudo batterycontrol start             # Start BatteryControl"`<br>
`sudo batterycontrol stop              # Stop BatteryControl"`<br>
`sudo batterycontrol set 80 75         # Set max/min battery charge thresholds"`<br>
`sudo batterycontrol startup           # Initiate batterycontrol /etc/init .conf installer"`<br>
`sudo batterycontrol help              # Help menu"`<br>

----------------------------------------------------------------------------------------------
<br>

*FanControl:*

`sudo fancontrol                       # Show fan status"`<br>
`sudo fancontrol start                 # Start FanControl"`<br>
`sudo fancontrol stop                  # Stop FanControl"`<br>
`sudo fancontrol min_temp 50           # Min temp threshold"`<br>
`sudo fancontrol max_temp 90           # Max temp threshold"`<br>
`sudo fancontrol min_fan 0             # Min fan speed %"`<br>
`sudo fancontrol max_fan 100           # Max fan speed %"`<br>
`sudo fancontrol stepup 20             # Fan step-up %"`<br>
`sudo fancontrol stepdown 1            # Fan step-down %"`<br>
`sudo fancontrol startup               # Initiate fancontrol /etc/init .conf installer"`<br>
`sudo fancontrol help                  # Help menu"`<br>

----------------------------------------------------------------------------------------------
<br>

*Uninstall:*

- `sudo powercontrol uninstall            # Global uninstaller that will clean up after itself`
- Alternative uninstall method: `sudo /usr/local/bin/ChromeOS_PowerControl/Uninstall_ChromeOS_PowerControl.sh`
<br> <br> <br>

How It Works:

<br>

*PowerControl:*

- Uses ARM, AMD, and Intel's max_perf_pct for easy user control.
- Pairs user adjustable max_perf_pct and thermal0 temp sensor to create a user adjustable clockspeed-temperature curve. 
- If $min_temp threshold is below a certain point, the CPU will be able to reach max_perf_pct of its speed.
- The closer the CPU approaches $max_temp, the closer it is to min_perf_pct.

<br>

*BatteryControl:*

- Uses ectool's chargecontrol to toggle between normal or idle.
- Check's CROS_USBPD_CHARGER0/online to see if it is plugged in or not.
- Check's BAT0/capacity to measure when to control chargecontrol.
- ChromeOS reports slightly higher values than what BatteryControl sets the charge limit to.<br>

<br>

*FanControl:*

- Uses ectool's fanduty control and autofanctrl for manual and automatic control.
- Pairs fanduty with thermal0 temperature sensor for a user adjustable fan-temperature curve.
- Uses hysteresis formula to attempt a better sounding and performing fan curve than the OEM provides. 
- Uses a kickstart mechanism when fan leaves 0% to enable zero RPM mode for any fan type.

<br>

Bonus:
- To disable rootfs verification open VT-2, login as root, and run:
 `/usr/libexec/debugd/helpers/dev_features_rootfs_verification`
- Enable sudo for crosh: `https://gist.github.com/velzie/a5088c9ade6ec4d35435b9826b45d7a3`

Credits:

- Thanks to WesBosch for helping me learn to make an installer:
  https://github.com/WesBosch
  
- Thanks to DennyL on ChromeOS discord for showing me how to enable sudo on crosh, test out PowerControl, and provide many great suggestions. 

