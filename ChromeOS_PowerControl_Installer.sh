#!/bin/bash
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
BLUE=$(tput setaf 4)
MAGENTA=$(tput setaf 5)
CYAN=$(tput setaf 6)
BOLD=$(tput bold)
RESET=$(tput sgr0)
SHOW_POWERCONTROL_NOTICE=0
SHOW_BATTERYCONTROL_NOTICE=0
SHOW_SLEEPCONTROL_NOTICE=0
SHOW_GPUCONTROL_NOTICE=0


detect_cpu_type() {
    CPU_VENDOR=$(grep -m1 'vendor_id' /proc/cpuinfo | awk '{print $3}' || echo "unknown")
    IS_INTEL=0
    IS_AMD=0
    IS_ARM=0
    case "$CPU_VENDOR" in
        GenuineIntel)
            IS_INTEL=1
            PERF_PATH="/sys/devices/system/cpu/intel_pstate/max_perf_pct"
            TURBO_PATH="/sys/devices/system/cpu/intel_pstate/no_turbo"
            ;;
        AuthenticAMD)
            IS_AMD=1
            if [ -f "/sys/devices/system/cpu/amd_pstate/max_perf_pct" ]; then
                PERF_PATH="/sys/devices/system/cpu/amd_pstate/max_perf_pct"
            else
                PERF_PATH="/sys/devices/system/cpu/cpufreq/policy0/scaling_max_freq"
            fi
            TURBO_PATH=""
            ;;
        *)
            IS_ARM=1
            PERF_PATH="/sys/devices/system/cpu/cpufreq/policy0/scaling_max_freq"
            TURBO_PATH=""
            ;;
    esac
}
detect_gpu_freq() {
    GPU_FREQ_PATH=""
    GPU_MAX_FREQ=""
    # Xe
    if [ -f "/sys/class/drm/card0/gt_max_freq_mhz" ]; then
        GPU_FREQ_PATH="/sys/class/drm/card0/gt_max_freq_mhz"
        GPU_MAX_FREQ=$(cat "$GPU_FREQ_PATH")
        GPU_TYPE="intel"
        return
    fi
  # Radeon
if [ -f "/sys/class/drm/card0/device/pp_od_clk_voltage" ]; then
    GPU_TYPE="amd"
    PP_OD_FILE="/sys/class/drm/card0/device/pp_od_clk_voltage"

    mapfile -t SCLK_LINES < <(grep -i '^sclk' "$PP_OD_FILE")

    if [[ ${#SCLK_LINES[@]} -gt 0 ]]; then
        MAX_MHZ=$(printf '%s\n' "${SCLK_LINES[@]}" | sed -n 's/.*\([0-9]\{1,\}\)[Mm][Hh][Zz].*/\1/p' | sort -nr | head -n1)
        if [[ -n "$MAX_MHZ" ]]; then
            GPU_MAX_FREQ="$MAX_MHZ"
            AMD_SELECTED_SCLK_INDEX=$(printf '%s\n' "${SCLK_LINES[@]}" | grep -in "$MAX_MHZ" | head -n1 | cut -d':' -f1)
            AMD_SELECTED_SCLK_INDEX=$((AMD_SELECTED_SCLK_INDEX - 1))
        else
            GPU_MAX_FREQ=0
            AMD_SELECTED_SCLK_INDEX=0
        fi
    else
        GPU_MAX_FREQ=0
        AMD_SELECTED_SCLK_INDEX=0
    fi
    GPU_FREQ_PATH="$PP_OD_FILE"
    return
fi

    # Mali
    if [ -d "/sys/class/devfreq/mali0" ]; then
        if [ -f "/sys/class/devfreq/mali0/max_freq" ]; then
            GPU_FREQ_PATH="/sys/class/devfreq/mali0/max_freq"
            GPU_MAX_FREQ=$(cat "$GPU_FREQ_PATH")
            GPU_TYPE="mali"
            return
        elif [ -f "/sys/class/devfreq/mali0/available_frequencies" ]; then
            GPU_FREQ_PATH="/sys/class/devfreq/mali0/available_frequencies"
            MAX_FREQ=$(tr ' ' '\n' < "$GPU_FREQ_PATH" | sort -nr | head -n1)
            GPU_MAX_FREQ=$MAX_FREQ
            GPU_TYPE="mali"
            return
        fi
    fi
    # Adreno
    if [ -d "/sys/class/kgsl/kgsl-3d0" ]; then
        if [ -f "/sys/class/kgsl/kgsl-3d0/max_gpuclk" ]; then
            GPU_FREQ_PATH="/sys/class/kgsl/kgsl-3d0/max_gpuclk"
            GPU_MAX_FREQ=$(cat "$GPU_FREQ_PATH")
            GPU_TYPE="adreno"
            return
        elif [ -f "/sys/class/kgsl/kgsl-3d0/gpuclk" ]; then
            GPU_FREQ_PATH="/sys/class/kgsl/kgsl-3d0/gpuclk"
            GPU_MAX_FREQ=$(cat "$GPU_FREQ_PATH")
            GPU_TYPE="adreno"
            return
        fi
    fi
    GPU_FREQ_PATH=""
    GPU_MAX_FREQ=""
    GPU_TYPE="unknown"
}

detect_backlight_path() {
    BACKLIGHT_BASE="/sys/class/backlight"
    BRIGHTNESS_PATH=""
    MAX_BRIGHTNESS_PATH=""
    BACKLIGHT_NAME=""

    if [ ! -d "$BACKLIGHT_BASE" ]; then
        echo "No backlight sysfs found at $BACKLIGHT_BASE"
        return 1
    fi
    
    for candidate in intel_backlight amdgpu_bl0 radeon_bl0 panel0-backlight pwm-backlight acpi_video0 backlight; do
        if [ -d "$BACKLIGHT_BASE/$candidate" ]; then
            BACKLIGHT_NAME="$candidate"
            BRIGHTNESS_PATH="$BACKLIGHT_BASE/$candidate/brightness"
            MAX_BRIGHTNESS_PATH="$BACKLIGHT_BASE/$candidate/max_brightness"
            
            if [ -r "$BRIGHTNESS_PATH" ] && [ -r "$MAX_BRIGHTNESS_PATH" ]; then
                break
            else
                BRIGHTNESS_PATH=""
                MAX_BRIGHTNESS_PATH=""
                BACKLIGHT_NAME=""
            fi
        fi
    done

    if [ -z "$BRIGHTNESS_PATH" ] || [ -z "$MAX_BRIGHTNESS_PATH" ]; then
        for dir in "$BACKLIGHT_BASE"/*; do
            if [ -d "$dir" ] && [ -r "$dir/brightness" ] && [ -r "$dir/max_brightness" ]; then
                BACKLIGHT_NAME=$(basename "$dir")
                BRIGHTNESS_PATH="$dir/brightness"
                MAX_BRIGHTNESS_PATH="$dir/max_brightness"
                break
            fi
        done
    fi

    if [ -z "$BRIGHTNESS_PATH" ] || [ -z "$MAX_BRIGHTNESS_PATH" ]; then
        echo "No valid backlight interface found."
        return 1
    fi
}


INSTALL_DIR="/usr/local/bin/ChromeOS_PowerControl"
echo "${YELLOW}"
echo "╔═══════════════════════════════════════════════════════════════════════════════════════════════╗"
echo "║                                          NOTICE:                                              ║"
echo "║                                                                                               ║"
echo "║             VT-2 (or enabling sudo in crosh) is required to run this installer!               ║"
echo "║               Must be installed in a location without the noexec mount.                       ║"
echo "╚═══════════════════════════════════════════════════════════════════════════════════════════════╝"
echo "${RESET}"
while true; do
    read -rp "${GREEN}Enter desired Install Path - ${RESET}${GREEN}${BOLD}leave blank for default: $INSTALL_DIR:$RESET " choice
    if [ -n "$choice" ]; then
        INSTALL_DIR="${choice:-/usr/local/bin/ChromeOS_PowerControl}"
    fi
    INSTALL_DIR="${INSTALL_DIR%/}"

    echo -e "\n${CYAN}You entered: ${BOLD}$INSTALL_DIR${RESET}"
    read -rp "${YELLOW}${BOLD}Confirm this install path? Enter key counts as yes!${RESET}${BOLD} (Y/n): ${RESET}" confirm
    case "$confirm" in
        [Yy]* | "")  
            sudo mkdir -p "$INSTALL_DIR"
            echo ""
            break
            ;;
        [Nn]*) 
            echo -e "${BLUE}Cancelled.${RESET}\n"
            ;;
        *) 
            echo -e "${RED}Please answer Y/n.${RESET}"
            ;;
    esac
done



declare -a files=(
  "powercontrol" "batterycontrol" "fancontrol" "gpucontrol" "Uninstall_ChromeOS_PowerControl.sh" "LICENSE" 
  "README.md" "no_turbo.conf" "batterycontrol.conf" "powercontrol.conf" "fancontrol.conf" "gpucontrol.conf" 
  "sleepcontrol" "sleepcontrol.conf" "config.sh" "version"
)

for file in "${files[@]}"; do
    dest="$INSTALL_DIR/$file"
    if [[ "$file" == "config.sh" && -f "$dest" ]]; then
        echo "${GREEN}Skipping existing config: $dest ${RESET}"
        echo ""
        continue
    fi
        echo "Downloading $file to $dest..."
    if curl -fsSL "https://raw.githubusercontent.com/shadowed1/ChromeOS_PowerControl/main/$file" -o "$dest"; then
        if grep -q "@INSTALL_DIR@" "$dest"; then
            sed -i "s|@INSTALL_DIR@|$INSTALL_DIR|g" "$dest"
        fi
        chmod +x "$dest"
    else
        echo "${RED}Failed to download $file. Skipping.${RESET}"
    fi
    echo ""
done

FAN_COUNT=$(sudo ectool pwmgetnumfans | awk -F= '{print $2}' | sed -e 's/ //g')

if [ "$FAN_COUNT" -eq 0 ]; then
    echo "${GREEN}Passively cooled device detected, skipping FanControl setup.${RESET}"
    SKIP_FANCONTROL=true
    sed -i '/^STARTUP_FANCONTROL=/d' "$CONFIG_FILE" 2>/dev/null
    echo "STARTUP_FANCONTROL=0" >> "$CONFIG_FILE"
else
    SKIP_FANCONTROL=false
fi

detect_backlight_path
detect_cpu_type

if [ "$IS_INTEL" -eq 1 ]; then
    SHOW_POWERCONTROL_NOTICE=1
fi
echo ""
echo "${GREEN}$BACKLIGHT_NAME"
echo "$BRIGHTNESS_PATH"
echo "$MAX_BRIGHTNESS_PATH${RESET}"
echo ""

echo "${CYAN}Detected CPU Vendor: $CPU_VENDOR"
echo "PERF_PATH: $PERF_PATH"
echo "TURBO_PATH: $TURBO_PATH"
echo "$RESET"
sudo chmod +x "$INSTALL_DIR/powercontrol" "$INSTALL_DIR/batterycontrol" "$INSTALL_DIR/fancontrol" "$INSTALL_DIR/gpucontrol" "$INSTALL_DIR/sleepcontrol" "$INSTALL_DIR/Uninstall_ChromeOS_PowerControl.sh" "$INSTALL_DIR/config.sh"
sudo touch "$INSTALL_DIR/.batterycontrol_enabled" "$INSTALL_DIR/.powercontrol_enabled" "$INSTALL_DIR/.fancontrol_enabled"
detect_gpu_freq
echo "${MAGENTA}Detected GPU Type: $GPU_TYPE"
echo "GPU_FREQ_PATH: $GPU_FREQ_PATH"
echo "GPU_MAX_FREQ: $GPU_MAX_FREQ"
echo "${RESET}"

LOG_DIR="/var/log"
CONFIG_FILE="$INSTALL_DIR/config.sh"
sudo touch "$LOG_DIR/powercontrol.log" "$LOG_DIR/batterycontrol.log" "$LOG_DIR/fancontrol.log" "$LOG_DIR/gpucontrol.log" "$LOG_DIR/sleepcontrol.log"
sudo chmod 644 "$LOG_DIR/powercontrol.log" "$LOG_DIR/batterycontrol.log" "$LOG_DIR/fancontrol.log" "$LOG_DIR/gpucontrol.log" "$LOG_DIR/sleepcontrol.log"
echo "${YELLOW}${BOLD}Log files for PowerControl, BatteryControl, FanControl, GPUControl, and SleepControl are stored in /var/log/$RESET"
echo ""

USER_HOME="/home/chronos"
echo ""

declare -a ordered_keys=(
  "MAX_TEMP"
  "MAX_PERF_PCT"
  "MIN_TEMP"
  "MIN_PERF_PCT"
  "HOTZONE"
  "CPU_POLL"
  "RAMP_UP"
  "RAMP_DOWN"
  "CHARGE_MAX"
  "FAN_MIN_TEMP"
  "FAN_MAX_TEMP"
  "MIN_FAN"
  "MAX_FAN"
  "FAN_POLL"
  "STEP_UP"
  "STEP_DOWN"
  "GPU_TYPE"
  "GPU_FREQ_PATH"
  "GPU_MAX_FREQ"
  "BATTERY_DELAY"
  "BATTERY_BACKLIGHT"
  "BATTERY_DIM_DELAY"
  "POWER_DELAY"
  "POWER_BACKLIGHT"
  "POWER_DIM_DELAY"
  "AUDIO_DETECTION_BATTERY"
  "AUDIO_DETECTION_POWER"
  "PERF_PATH"
  "TURBO_PATH"
  "ORIGINAL_GPU_MAX_FREQ"
  "PP_OD_FILE"
  "AMD_SELECTED_SCLK_INDEX"
  "IS_AMD"
  "IS_INTEL"
  "IS_ARM"
  "BACKLIGHT_NAME"
  "BRIGHTNESS_PATH"
  "MAX_BRIGHTNESS_PATH"
)

declare -a ordered_categories=("PowerControl" "BatteryControl" "FanControl" "GPUControl" "SleepControl" "Platform Configuration")
declare -A categories=(
  ["PowerControl"]="MAX_TEMP MIN_TEMP MAX_PERF_PCT MIN_PERF_PCT HOTZONE CPU_POLL RAMP_UP RAMP_DOWN"
  ["BatteryControl"]="CHARGE_MAX"
  ["FanControl"]="MIN_FAN MAX_FAN FAN_MIN_TEMP FAN_MAX_TEMP STEP_UP STEP_DOWN FAN_POLL"
  ["GPUControl"]="GPU_MAX_FREQ"
  ["SleepControl"]="BATTERY_DELAY BATTERY_BACKLIGHT BATTERY_DIM_DELAY POWER_DELAY POWER_BACKLIGHT POWER_DIM_DELAY AUDIO_DETECTION_BATTERY AUDIO_DETECTION_POWER"
  ["Platform Configuration"]="IS_AMD IS_INTEL IS_ARM PERF_PATH TURBO_PATH GPU_TYPE GPU_FREQ_PATH ORIGINAL_GPU_MAX_FREQ PP_OD_FILE AMD_SELECTED_SCLK_INDEX BACKLIGHT_NAME BRIGHTNESS_PATH MAX_BRIGHTNESS_PATH"
)

if [[ -z "${ORIGINAL_GPU_MAX_FREQ}" ]]; then ORIGINAL_GPU_MAX_FREQ=$GPU_MAX_FREQ; fi
if [[ -z "${MAX_TEMP}" ]]; then MAX_TEMP=87; fi
if [[ -z "${MIN_TEMP}" ]]; then MIN_TEMP=60; fi
if [[ -z "${MAX_PERF_PCT}" ]]; then MAX_PERF_PCT=100; fi
if [[ -z "${MIN_PERF_PCT}" ]]; then MIN_PERF_PCT=40; fi
if [[ -z "${HOTZONE}" ]]; then HOTZONE=80; fi
if [[ -z "${CPU_POLL}" ]]; then CPU_POLL=1; fi
if [[ -z "${RAMP_UP}" ]]; then RAMP_UP=15; fi
if [[ -z "${RAMP_DOWN}" ]]; then RAMP_DOWN=20; fi
if [[ -z "${CHARGE_MAX}" ]]; then CHARGE_MAX=77; fi
if [[ -z "${MIN_FAN}" ]]; then MIN_FAN=0; fi
if [[ -z "${MAX_FAN}" ]]; then MAX_FAN=100; fi
if [[ -z "${FAN_MIN_TEMP}" ]]; then FAN_MIN_TEMP=46; fi
if [[ -z "${FAN_MAX_TEMP}" ]]; then FAN_MAX_TEMP=80; fi
if [[ -z "${STEP_UP}" ]]; then STEP_UP=20; fi
if [[ -z "${STEP_DOWN}" ]]; then STEP_DOWN=1; fi
if [[ -z "${FAN_POLL}" ]]; then FAN_POLL=3; fi
if [[ -z "${BATTERY_DELAY}" ]]; then BATTERY_DELAY=12; fi
if [[ -z "${BATTERY_BACKLIGHT}" ]]; then BATTERY_BACKLIGHT=7; fi
if [[ -z "${BATTERY_DIM_DELAY}" ]]; then BATTERY_DIM_DELAY=3; fi
if [[ -z "${POWER_DELAY}" ]]; then POWER_DELAY=30; fi
if [[ -z "${POWER_BACKLIGHT}" ]]; then POWER_BACKLIGHT=15; fi
if [[ -z "${POWER_DIM_DELAY}" ]]; then POWER_DIM_DELAY=5; fi
if [[ -z "${AUDIO_DETECTION_BATTERY}" ]]; then AUDIO_DETECTION_BATTERY=0; fi
if [[ -z "${AUDIO_DETECTION_POWER}" ]]; then AUDIO_DETECTION_POWER=1; fi


declare -A defaults=(
  [MAX_TEMP]=$MAX_TEMP
  [MIN_TEMP]=$MIN_TEMP
  [MAX_PERF_PCT]=$MAX_PERF_PCT
  [MIN_PERF_PCT]=$MIN_PERF_PCT
  [HOTZONE]=$HOTZONE
  [CPU_POLL]=$CPU_POLL
  [RAMP_UP]=$RAMP_UP
  [RAMP_DOWN]=$RAMP_DOWN
  [CHARGE_MAX]=$CHARGE_MAX
  [MIN_FAN]=$MIN_FAN
  [MAX_FAN]=$MAX_FAN
  [FAN_MIN_TEMP]=$FAN_MIN_TEMP
  [FAN_MAX_TEMP]=$FAN_MAX_TEMP
  [STEP_UP]=$STEP_UP
  [STEP_DOWN]=$STEP_DOWN
  [FAN_POLL]=$FAN_POLL
  [GPU_MAX_FREQ]=$GPU_MAX_FREQ
  [GPU_TYPE]=$GPU_TYPE
  [BATTERY_DELAY]=$BATTERY_DELAY
  [POWER_DELAY]=$POWER_DELAY
  [BATTERY_BACKLIGHT]=$BATTERY_BACKLIGHT
  [POWER_BACKLIGHT]=$POWER_BACKLIGHT
  [AUDIO_DETECTION_BATTERY]=$AUDIO_DETECTION_BATTERY
  [AUDIO_DETECTION_POWER]=$AUDIO_DETECTION_POWER
  [PERF_PATH]=$PERF_PATH
  [TURBO_PATH]=$TURBO_PATH
  [GPU_FREQ_PATH]=$GPU_FREQ_PATH
  [ORIGINAL_GPU_MAX_FREQ]=$GPU_MAX_FREQ
  [PP_OD_FILE]=$PP_OD_FILE
  [AMD_SELECTED_SCLK_INDEX]=$AMD_SELECTED_SCLK_INDEX
  [IS_AMD]=$IS_AMD
  [IS_INTEL]=$IS_INTEL
  [IS_ARM]=$IS_ARM
  [BACKLIGHT_NAME]=$BACKLIGHT_NAME
  [BRIGHTNESS_PATH]=$BRIGHTNESS_PATH
  [MAX_BRIGHTNESS_PATH]=$MAX_BRIGHTNESS_PATH
)

if [ -f "$CONFIG_FILE" ]; then
  source "$CONFIG_FILE"
fi

> "$CONFIG_FILE" 

for category in "${ordered_categories[@]}"; do
  echo "# --- ${category} ---" >> "$CONFIG_FILE"
  for key in ${categories[$category]}; do
        if [ -n "${!key+x}" ]; then
          val="${!key}"
        else
          val="${defaults[$key]}"
        fi
    echo "$key=$val" >> "$CONFIG_FILE"
  done
  echo >> "$CONFIG_FILE"
done
echo "${GREEN}${BOLD}Installing to: $INSTALL_DIR $RESET"
echo ""
echo ""


read -rp "Enable ${BOLD}Global Commands${RESET} for ${RESET}${BOLD}${CYAN}PowerControl${RESET}, ${GREEN}${BOLD}BatteryControl${RESET}, ${YELLOW}${BOLD}FanControl${RESET}, ${BOLD}${MAGENTA}GPUControl${RESET}, ${BOLD}${BLUE}SleepControl${RESET}?${RESET}${BOLD} (Y/n):$RESET " link_cmd
if [[ -z "$link_cmd" || "$link_cmd" =~ ^[Yy]$ ]]; then
    sudo ln -sf "$INSTALL_DIR/powercontrol" /usr/local/bin/powercontrol
    sudo ln -sf "$INSTALL_DIR/batterycontrol" /usr/local/bin/batterycontrol
    sudo ln -sf "$INSTALL_DIR/fancontrol" /usr/local/bin/fancontrol
    sudo ln -sf "$INSTALL_DIR/gpucontrol" /usr/local/bin/gpucontrol
    sudo ln -sf "$INSTALL_DIR/sleepcontrol" /usr/local/bin/sleepcontrol
    echo "Symbolic links created!"
    echo ""
else
    echo "Skipped creating global commands."
    sudo rm -r /usr/local/bin/powercontrol > /dev/null 2>&1
    sudo rm -r /usr/local/bin/batterycontrol > /dev/null 2>&1
    sudo rm -r /usr/local/bin/fancontrol > /dev/null 2>&1
    sudo rm -r /usr/local/bin/gpucontrol > /dev/null 2>&1
    sudo rm -r /usr/local/bin/sleepcontrol > /dev/null 2>&1
    echo ""
fi
enable_component_on_boot() {
    
    local COLOR
    local component="$1"
    local config_file="$2"
    local var_name="STARTUP_$(echo "$component" | tr '[:lower:]' '[:upper:]')"
    local target_file="/etc/init/$(basename "$config_file")"

     case "$component" in
        "PowerControl")   COLOR=${CYAN}${BOLD} ;;
        "GPUControl")     COLOR=${MAGENTA}${BOLD} ;;
        "FanControl")     COLOR=${YELLOW}${BOLD} ;;
        "BatteryControl") COLOR=${GREEN}${BOLD} ;;
        "SleepControl")   COLOR=${BLUE}${BOLD} ;;
        *)                COLOR=${RESET} ;;
    esac
    
    read -rp "${COLOR}Do you want $component enabled on boot?${RESET}${BOLD} (Y/n):${RESET} " move_config
    if [[ -z "$move_config" || "$move_config" =~ ^[Yy]$ ]]; then
        sudo cp "$config_file" "$target_file"
        echo "$component will start on boot."
        echo "$var_name=1" | sudo tee -a "$CONFIG_FILE" > /dev/null
        echo ""
    else
        echo "$component must be started manually on boot."
        echo "$var_name=0" | sudo tee -a "$CONFIG_FILE" > /dev/null

        if [ -f "$target_file" ]; then
            sudo rm -f "$target_file"
        fi
        echo ""
    fi
}

if [[ -z "$link_cmd" || "$link_cmd" =~ ^[Yy]$ ]]; then
    enable_component_on_boot "BatteryControl" "$INSTALL_DIR/batterycontrol.conf"
    enable_component_on_boot "PowerControl" "$INSTALL_DIR/powercontrol.conf"

    if [ "$SKIP_FANCONTROL" = false ]; then
        enable_component_on_boot "FanControl" "$INSTALL_DIR/fancontrol.conf"
    else
        echo "${GREEN}Skipping FanControl boot setup. No fan to control.${RESET}"
    fi

    enable_component_on_boot "GPUControl" "$INSTALL_DIR/gpucontrol.conf"
    enable_component_on_boot "SleepControl" "$INSTALL_DIR/sleepcontrol.conf"
else
    echo "Skipping boot-time setup since global commands were declined."
fi



if grep -q '^STARTUP_GPUCONTROL=1' "$CONFIG_FILE"; then
    SHOW_GPUCONTROL_NOTICE=1
fi

if grep -q '^STARTUP_BATTERYCONTROL=1' "$CONFIG_FILE"; then
    SHOW_BATTERYCONTROL_NOTICE=1
fi

if grep -q '^STARTUP_SLEEPCONTROL=1' "$CONFIG_FILE"; then
    SHOW_SLEEPCONTROL_NOTICE=1
fi
if grep -q '^STARTUP_POWERCONTROL=1' "$CONFIG_FILE"; then
    SHOW_POWERCONTROL_NOTICE=1
fi
start_component_now() {
    local component="$1"
    local command="$2"
    local COLOR

    case "$component" in
        "PowerControl")   COLOR=${CYAN}${BOLD} ;;
        "GPUControl")     COLOR=${MAGENTA}${BOLD} ;;
        "FanControl")     COLOR=${YELLOW}${BOLD} ;;
        "BatteryControl") COLOR=${GREEN}${BOLD} ;;
        "SleepControl")   COLOR=${BLUE}${BOLD} ;;
        *)                COLOR=${RESET} ;;
    esac

    read -rp "${COLOR}Do you want to start $component now?${RESET}${BOLD} (Y/n): ${RESET} " start_now
    if [[ -z "$start_now" || "$start_now" =~ ^[Yy]$ ]]; then
        sudo "$command" start
        echo ""

        if [[ "$component" == "BatteryControl" ]]; then
            declare -g SHOW_BATTERYCONTROL_NOTICE=1
        fi

        if [[ "$component" == "GPUControl" ]]; then
            declare -g SHOW_GPUCONTROL_NOTICE=1
        fi

        if [[ "$component" == "SleepControl" ]]; then
            declare -g SHOW_SLEEPCONTROL_NOTICE=1
        fi

        if [[ "$component" == "PowerControl" ]]; then
            declare -g SHOW_POWERCONTROL_NOTICE=1

            if [[ -e /sys/devices/system/cpu/intel_pstate/no_turbo ]]; then
                read -rp "${BOLD}${CYAN}Do you want Intel Turbo Boost ${RESET}${BOLD}${BLUE}disabled on boot${RESET}${BOLD}${CYAN}?${RESET}${BOLD} (Y/n):$RESET " move_no_turbo
                if [[ -z "$move_no_turbo" || "$move_no_turbo" =~ ^[Yy]$ ]]; then
                    sudo cp "$INSTALL_DIR/no_turbo.conf" /etc/init/
                    echo "Turbo Boost will be disabled on restart."
                    echo "${CYAN}sudo powercontrol startup${RESET}     # To re-enable Turbo Boost on boot."
                    echo ""
                else
                    sudo rm -f /etc/init/no_turbo.conf
                    echo "Turbo Boost will remain enabled."
                    echo "${CYAN}sudo powercontrol startup${RESET}     # To disable Intel Turbo Boost on boot."
                    echo ""
                fi

                read -rp "${BOLD}${CYAN}Do you want to ${RESET}${BOLD}${BLUE}disable${RESET}${CYAN}${BOLD} Intel Turbo Boost ${RESET}${BOLD}${BLUE}now${RESET}${BOLD}${CYAN}?${RESET}${BOLD} (Y/n):$RESET " run_no_turbo
                if [[ -z "$run_no_turbo" || "$run_no_turbo" =~ ^[Yy]$ ]]; then
                    echo 1 | sudo tee /sys/devices/system/cpu/intel_pstate/no_turbo > /dev/null
                    echo "Turbo Boost disabled immediately."
                    echo "${CYAN}sudo powercontrol no_turbo 0${RESET}     # To re-enable Intel Turbo Boost"
                    echo ""
                else
                    echo 0 | sudo tee /sys/devices/system/cpu/intel_pstate/no_turbo > /dev/null
                    echo "Turbo Boost remains enabled."
                    echo "${CYAN}sudo powercontrol no_turbo 1${RESET}    # To disable Intel Turbo Boost"
                    echo ""
                fi
            else
                echo "This is not an Intel CPU, skipping Turbo Boost options."
                echo ""
            fi
        fi

    else
        echo "You can run it later with: sudo $command start"
        echo ""
    fi
}



echo "${BLUE}Stopping any running components of PowerControl${RESET}"
sudo bash "$INSTALL_DIR/gpucontrol" restore >/dev/null 2>&1
sudo ectool backlight 1 >/dev/null 2>&1
for component in batterycontrol powercontrol fancontrol sleepcontrol; do
    if command -v "$INSTALL_DIR/$component" >/dev/null 2>&1; then
        sudo bash "$INSTALL_DIR/$component" stop >/dev/null 2>&1
    fi
done

for service in no_turbo batterycontrol powercontrol fancontrol gpu_control; do
    sudo initctl stop "$service" 2>/dev/null
done

echo ""
start_component_now "BatteryControl" "$INSTALL_DIR/batterycontrol"
start_component_now "PowerControl" "$INSTALL_DIR/powercontrol"
if [ "$SKIP_FANCONTROL" = false ]; then
    start_component_now "FanControl" "$INSTALL_DIR/fancontrol"
else
    echo "${YELLOW}FanControl start skipped - no fans detected.${RESET}"
fi
start_component_now "SleepControl" "$INSTALL_DIR/sleepcontrol"

echo ""
echo "                                                       ${RED}████████████${RESET}           "
echo "                                                   ${RED}████${RESET}        ${RED}████${RESET}       "
echo "                                                 ${RED}██${RESET}              ${YELLOW}██${RESET}     "
echo "                                               ${GREEN}██${RESET}     ${BLUE}██████${RESET}     ${YELLOW}██${RESET}   "
echo "                                              ${GREEN}██${RESET}     ${BLUE}████████${RESET}     ${YELLOW}██${RESET}  "
echo "                                              ${GREEN}██${RESET}     ${BLUE}████████${RESET}     ${YELLOW}██${RESET}  "
echo "                                               ${GREEN}██${RESET}     ${BLUE}██████${RESET}     ${YELLOW}██${RESET}   "
echo "                                                 ${GREEN}██${RESET}              ${YELLOW}██${RESET}     "
echo "                                                   ${GREEN}████${RESET}        ${YELLOW}████${RESET}       "
echo "                                                       ${GREEN}████████████${RESET}           "
echo ""
echo "                                         ${RED}╔═══════════════════════════════╗${RESET}"
echo "                                         ${YELLOW}║ ╔═══════════════════════════╗ ║${RESET}"
echo "                                         ${GREEN}║ ║ ╔═══════════════════════╗ ║ ║${RESET}"
echo "                                         ${RESET}║ ║ ║ ChromeOS_PowerControl ║ ║ ║${RESET}"
echo "                                         ${CYAN}║ ║ ╚═══════════════════════╝ ║ ║${RESET}"
echo "                                         ${BLUE}║ ╚═══════════════════════════╝ ║${RESET}"
echo "                                         ${MAGENTA}╚═══════════════════════════════╝${RESET}"
echo ""
echo ""
echo "                                              Commands with examples:"
echo "${CYAN}"
echo "╔════════════════════════════════════════════════════════════════════════════════════════════════════════════════════╗"
echo "║                                                  PowerControl:                                                     ║"
echo "╠════════════════════════════════════════════════════════════════════════════════════════════════════════════════════╣"
echo "║                                                                                                                    ║"
echo "║  powercontrol                       # Show status                                                                  ║"
echo "║  sudo powercontrol start            # Throttle CPU based on temperature curve                                      ║"
echo "║  sudo powercontrol stop             # Restore default CPU settings                                                 ║"
echo "║  sudo powercontrol no_turbo 1       # 0 = Enable, 1 = Disable Turbo Boost                                          ║"
echo "║  sudo powercontrol max_perf_pct 75  # Set max performance percentage                                               ║"
echo "║  sudo powercontrol min_perf_pct 50  # Set minimum performance at max temp                                          ║"
echo "║  sudo powercontrol max_temp 86      # Max temperature threshold - Limit is 90°C                                    ║"
echo "║  sudo powercontrol min_temp 60      # Min temperature threshold                                                    ║"
echo "║  sudo powercontrol hotzone 78       # Temperature threshold for aggressive thermal management                      ║"
echo "║  sudo powercontrol cpu_poll 1       # Interval in seconds PowerControl operates at (0.1s to 5s)                    ║"
echo "║  sudo powercontrol ramp_up 15       # % in steps CPU will increase in clockspeed per second                        ║"
echo "║  sudo powercontrol ramp_down 20     # % in steps CPU will decrease in clockspeed per second                        ║"
echo "║  sudo powercontrol monitor          # Toggle on/off live monitoring in terminal                                    ║"
echo "║  sudo powercontrol startup          # Copy or Remove no_turbo.conf & powercontrol.conf at: /etc/init/              ║"
echo "║  sudo powercontrol help             # Help menu                                                                    ║"
echo "║                                                                                                                    ║"
echo "╚════════════════════════════════════════════════════════════════════════════════════════════════════════════════════╝"
echo "${RESET}${GREEN}╔════════════════════════════════════════════════════════════════════════════════════════════════════════════════════╗"
echo "║                                                 BatteryControl:                                                    ║"
echo "╠════════════════════════════════════════════════════════════════════════════════════════════════════════════════════╣"
echo "║                                                                                                                    ║"
echo "║  batterycontrol               # Check BatteryControl status                                                        ║"
echo "║  sudo batterycontrol start    # Start BatteryControl                                                               ║"
echo "║  sudo batterycontrol stop     # Stop BatteryControl                                                                ║"
echo "║  sudo batterycontrol 77       # Charge limit set to 77% - minimum of 14% allowed                                   ║"
echo "║  sudo batterycontrol startup  # Copy or Remove batterycontrol.conf at: /etc/init/                                  ║"
echo "║  sudo batterycontrol help     # Help menu                                                                          ║"
echo "║                                                                                                                    ║"
echo "╚════════════════════════════════════════════════════════════════════════════════════════════════════════════════════╝"
echo "${RESET}${YELLOW}╔════════════════════════════════════════════════════════════════════════════════════════════════════════════════════╗"
echo "║                                                  FanControl:                                                       ║"
echo "╠════════════════════════════════════════════════════════════════════════════════════════════════════════════════════╣"
echo "║                                                                                                                    ║"
echo "║  fancontrol                       # Show FanControl status                                                         ║"
echo "║  sudo fancontrol start            # Start FanControl                                                               ║"
echo "║  sudo fancontrol stop             # Stop FanControl                                                                ║"
echo "║  sudo fancontrol fan_min_temp 48  # Min temp threshold                                                             ║"
echo "║  sudo fancontrol fan_max_temp 81  # Max temp threshold - Limit is 90°C                                             ║"
echo "║  sudo fancontrol min_fan 0        # Min fan speed %                                                                ║"
echo "║  sudo fancontrol max_fan 100      # Max fan speed %                                                                ║"
echo "║  sudo fancontrol step_up 20       # Fan step-up %                                                                  ║"
echo "║  sudo fancontrol step_down 1      # Fan step-down %                                                                ║"
echo "║  sudo fancontrol poll 2           # FanControl polling rate in seconds (1 to 10s)                                  ║"
echo "║  sudo fancontrol monitor          # Toggle on/off live monitoring in terminal                                      ║"
echo "║  sudo fancontrol startup          # Copy or Remove fancontrol.conf at: /etc/init/                                  ║"
echo "║  sudo fancontrol help             # Help menu                                                                      ║"
echo "║                                                                                                                    ║"
echo "╚════════════════════════════════════════════════════════════════════════════════════════════════════════════════════╝"
echo "${RESET}${MAGENTA}╔════════════════════════════════════════════════════════════════════════════════════════════════════════════════════╗"
echo "║                                                   GPUControl:                                                      ║"
echo "╠════════════════════════════════════════════════════════════════════════════════════════════════════════════════════╣"
echo "║                                                                                                                    ║"
echo "║  gpucontrol                     # Show current GPU info and frequency                                              ║"
echo "║  sudo gpucontrol restore        # Restore GPU max frequency to original value                                      ║"
echo "║  sudo gpucontrol intel 700      # Set Intel GPU max frequency to 700 MHz                                           ║"
echo "║  sudo gpucontrol amd 800        # Set AMD GPU max frequency to 800 MHz - rounds down to pp_od_clk_voltage index    ║"
echo "║  sudo gpucontrol adreno 500000  # Set Adreno GPU max frequency to 500000 kHz (or 500 MHz)                          ║"
echo "║  sudo gpucontrol mali 600000    # Set Mali GPU max frequency to 600000 kHz (or 600 MHz)                            ║"
echo "║  sudo gpucontrol startup        # Copy or Remove gpucontrol.conf at: /etc/init/                                    ║"
echo "║  sudo gpucontrol help           # Help menu                                                                        ║"
echo "║                                                                                                                    ║"
echo "╚════════════════════════════════════════════════════════════════════════════════════════════════════════════════════╝"
echo "${RESET}${BLUE}╔════════════════════════════════════════════════════════════════════════════════════════════════════════════════════╗"
echo "║                                                  SleepControl                                                      ║"
echo "╠════════════════════════════════════════════════════════════════════════════════════════════════════════════════════╣"
echo "║                                                                                                                    ║"
echo "║  sleepcontrol                       # Show SleepControl status                                                     ║"
echo "║  sudo sleepcontrol start            # Start SleepControl                                                           ║"
echo "║  sudo sleepcontrol stop             # Stop SleepControl                                                            ║"
echo "║  sudo sleepcontrol battery 3 7 12   # When idle, display dims in 3m -> timeout in 7m -> sleeps in 12m on battery   ║"
echo "║  sudo sleepcontrol power 5 15 30    # When idle, display dims in 5m -> timeout -> 15m -> sleeps in 30m plugged-in  ║"
echo "║  sudo sleepcontrol battery audio 0  # Disable audio detection on battery; sleep can occur during media playback    ║"
echo "║  sudo sleepcontrol power audio 1    # Enable audio detection on power; delaying sleep until audio is stopped       ║"
echo "║  sudo sleepcontrol startup          # Copy or Remove sleepcontrol.conf at: /etc/init/                              ║"
echo "║  sudo sleepcontrol help             # Help menu                                                                    ║"
echo "║                                                                                                                    ║"
echo "╚════════════════════════════════════════════════════════════════════════════════════════════════════════════════════╝"
echo "${RESET}${CYAN}${BOLD}╔════════════════════════════════════════════════════════════════════════════════════════════════════════════════════╗"
echo "║                                              ChromeOS_PowerControl                                                 ║"
echo "╠════════════════════════════════════════════════════════════════════════════════════════════════════════════════════╣"
echo "║                                                                                                                    ║"
echo "║  sudo powercontrol version    # Check PowerControl version                                                         ║"
echo "║  sudo powercontrol reinstall  # Download and reinstall ChromeOS_PowerControl                                       ║"
echo "║  sudo powercontrol uninstall  # Run uninstaller                                                                    ║"
echo "║                                                                                                                    ║"
echo "╚════════════════════════════════════════════════════════════════════════════════════════════════════════════════════╝"
echo "   sudo bash "$INSTALL_DIR/Uninstall_ChromeOS_PowerControl.sh"  # Alternate uninstall method"
echo " ════════════════════════════════════════════════════════════════════════════════════════════════════════════════════"
echo "${RESET}"

if [[ "$SHOW_BATTERYCONTROL_NOTICE" -eq 1 ]]; then
echo "${GREEN}"
echo "╔════════════════════════════════════════════════════════════════════════════════════════════════════════════════════╗"
echo "║   ${RESET}${GREEN}${BOLD}BatteryControl Notice:${RESET}${GREEN}                                                                                           ║"
echo "║   Disable Adaptive Charging in Settings → System Preferences → Power to avoid notification spam.                   ║"
echo "╚════════════════════════════════════════════════════════════════════════════════════════════════════════════════════╝${RESET}"
fi

if [[ "$SHOW_GPUCONTROL_NOTICE" -eq 1 ]]; then
echo "${MAGENTA}╔════════════════════════════════════════════════════════════════════════════════════════════════════════════════════╗"
echo "║  ${RESET}${MAGENTA}${BOLD}GPUControl Notice:${RESET}${MAGENTA}                                                                                                ║"
echo "║  As a precaution GPUControl has a 2 minute delay before applying custom clockspeed on boot.                        ║"
echo "╚════════════════════════════════════════════════════════════════════════════════════════════════════════════════════╝${RESET}"
fi

if [[ "$SHOW_SLEEPCONTROL_NOTICE" -eq 1 ]]; then
echo "${BLUE}╔════════════════════════════════════════════════════════════════════════════════════════════════════════════════════╗"
echo "║  ${RESET}${BLUE}${BOLD}SleepControl Notice:${RESET}${BLUE}                                                                                              ║"
echo "║  Overrides 'While inactive' preferences in System Preferences -> Power. Customize using commands above.            ║"
echo "╚════════════════════════════════════════════════════════════════════════════════════════════════════════════════════╝${RESET}"
echo ""
fi
echo "                                      ${RED}╔═══════════════════════════════╗${RESET}"
echo "                                      ${YELLOW}║ ╔═══════════════════════════╗ ║${RESET}"
echo "                                      ${GREEN}║ ║ ╔═══════════════════════╗ ║ ║${RESET}"
echo "                                      ${RESET}║ ║ ║ Installation Complete ║ ║ ║${RESET}"
echo "                                      ${CYAN}║ ║ ╚═══════════════════════╝ ║ ║${RESET}"
echo "                                      ${BLUE}║ ╚═══════════════════════════╝ ║${RESET}"
echo "                                      ${MAGENTA}╚═══════════════════════════════╝${RESET}"
echo ""
