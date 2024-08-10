#!/bin/bash

# IPMI iDrac Settings
IPMI_HOST="idrac.lab.local" # Your iDrac IP Address or FQDN
IPMI_USER="root"            # iDrac Username
IPMI_PASS="calvin"          # iDrac Password

# Fan Speed Thresholds
TEMP_THRESHOLD_1=50
TEMP_THRESHOLD_2=60
TEMP_THRESHOLD_3=65
TEMP_THRESHOLD_4=70
TEMP_THRESHOLD_5=75
TEMP_THRESHOLD_6=80
TEMP_THRESHOLD_7=85
TEMP_THRESHOLD_8=90

# Time Between Checks (in seconds)
CHECK_INTERVAL=60

# Log Path
LOG_FILE="/var/log/fanctrl.log"

# Danger Zone Temperature Threshold (in Celsius)
TEMP_MAX=90

# Init Current Fan Speed
current_fan_speed=""

# Logging
log() {
    level=$1
    message=$2
    timestamp=$(date +"%d-%m-%Y %H:%M:%S")
    log_message="[$timestamp] [$level] $message"
    echo "$log_message"
    echo "$log_message" >>"$LOG_FILE"
}

# Check Deps
check_dependencies() {
    dependencies=("ipmitool" "bc")
    for dep in "${dependencies[@]}"; do
        if ! command -v $dep &>/dev/null; then
            log "ERROR" "Required dependency '$dep' is not installed. Exiting."
            exit 1
        fi
    done
}

# Get CPU Temps and Parse Out Inlet & Exhaust
get_cpu_temperatures() {
    temps=$(ipmitool -I lanplus -H $IPMI_HOST -U $IPMI_USER -P $IPMI_PASS sdr type temperature | grep -E '^\s*Temp\s+\|' | awk -F'|' '{print $5}' | awk '{print $1}')
    if [ $? -ne 0 ]; then
        log "ERROR" "Failed to retrieve temperatures from IPMI. Error: $temps"
        echo ""
    else
        echo "$temps"
    fi
}

# Calculate Average CPU Temps From Both Procs
get_avg_cpu_temperature() {
    temps=$(get_cpu_temperatures)
    if [ -z "$temps" ]; then
        echo ""
    else
        echo "$temps" | awk '{sum+=$1} END {if (NR>0) print sum/NR; else print ""}' | awk '{printf "%.1f", $0}'
    fi
}

# Set The Fan Speed
set_fan_speed() {
    speed=$1
    if [ "$speed" != "$current_fan_speed" ]; then
        output=$(ipmitool -I lanplus -H $IPMI_HOST -U $IPMI_USER -P $IPMI_PASS raw 0x30 0x30 0x02 0xff $speed 2>&1)
        if [ $? -ne 0 ]; then
            log "ERROR" "Failed to set fan speed via IPMI. Error: $output"
        else
            log "INFO" "Fan speed set to $speed."
            current_fan_speed=$speed
        fi
    else
        log "INFO" "Fan speed unchanged at $speed."
    fi
}

# Manual Fan Control Mode
enable_manual_fan_control() {
    output=$(ipmitool -I lanplus -H $IPMI_HOST -U $IPMI_USER -P $IPMI_PASS raw 0x30 0x30 0x01 0x00 2>&1)
    if [ $? -ne 0 ]; then
        log "ERROR" "Failed to enable manual fan control via IPMI. Error: $output"
        exit 1
    else
        log "INFO" "Manual fan control enabled."
    fi
}

# Disable Fan Control Mode
disable_manual_fan_control() {
    output=$(ipmitool -I lanplus -H $IPMI_HOST -U $IPMI_USER -P $IPMI_PASS raw 0x30 0x30 0x01 0x01 2>&1)
    if [ $? -ne 0 ]; then
        log "ERROR" "Failed to disable manual fan control via IPMI. Error: $output"
    else
        log "INFO" "Manual fan control disabled. Returning to automatic control."
    fi
}

# If Script Exit Or Crash, Reset To Auto Fan Control
trap 'disable_manual_fan_control; log "INFO" "Script terminated."; exit 0' SIGINT SIGTERM

# Check For Required Deps
check_dependencies

# Takeover Fan Control On Launch
enable_manual_fan_control

# Main Loop
while true; do
    # Get CPU Temperatures
    cpu_temps=$(get_cpu_temperatures)
    log "INFO" "CPU temperatures:"
    i=0
    echo "$cpu_temps" | while read -r temp; do
        i=$((i + 1))
        log "INFO" "  CPU$i: $temp°C"
    done

    # Calculate Average Temp
    avg_temp=$(get_avg_cpu_temperature)

    if [ -z "$avg_temp" ]; then
        log "WARNING" "Unable to retrieve CPU temperatures. Skipping fan speed adjustment."
    else
        log "INFO" "Average CPU temperature: $avg_temp°C"

        # Check If The Temperature Exceeds The Max Threshold
        if (($(echo "$avg_temp >= $TEMP_MAX" | bc -l))); then
            log "WARNING" "Temperature reached or exceeded max threshold ($TEMP_MAX°C). Switching to automatic fan control."
            disable_manual_fan_control
            log "INFO" "Exiting script due to max temperature reached."
            exit 1
        # Step Up Fan Speed As Temp Goes Up
        elif (($(echo "$avg_temp >= $TEMP_THRESHOLD_8" | bc -l))); then
            log "WARNING" "Temperature above $TEMP_THRESHOLD_8°C. Setting fan speed to 90%."
            set_fan_speed 0x5A # 90%
        elif (($(echo "$avg_temp >= $TEMP_THRESHOLD_7" | bc -l))); then
            log "WARNING" "Temperature above $TEMP_THRESHOLD_7°C. Setting fan speed to 80%."
            set_fan_speed 0x50 # 80%
        elif (($(echo "$avg_temp >= $TEMP_THRESHOLD_6" | bc -l))); then
            log "INFO" "Temperature above $TEMP_THRESHOLD_6°C. Setting fan speed to 70%."
            set_fan_speed 0x46 # 70%
        elif (($(echo "$avg_temp >= $TEMP_THRESHOLD_5" | bc -l))); then
            log "INFO" "Temperature above $TEMP_THRESHOLD_5°C. Setting fan speed to 60%."
            set_fan_speed 0x3C # 60%
        elif (($(echo "$avg_temp >= $TEMP_THRESHOLD_4" | bc -l))); then
            log "INFO" "Temperature above $TEMP_THRESHOLD_4°C. Setting fan speed to 50%."
            set_fan_speed 0x32 # 50%
        elif (($(echo "$avg_temp >= $TEMP_THRESHOLD_3" | bc -l))); then
            log "INFO" "Temperature above $TEMP_THRESHOLD_3°C. Setting fan speed to 40%."
            set_fan_speed 0x28 # 40%
        elif (($(echo "$avg_temp >= $TEMP_THRESHOLD_2" | bc -l))); then
            log "INFO" "Temperature above $TEMP_THRESHOLD_2°C. Setting fan speed to 30%."
            set_fan_speed 0x1E # 30%
        elif (($(echo "$avg_temp >= $TEMP_THRESHOLD_1" | bc -l))); then
            log "INFO" "Temperature above $TEMP_THRESHOLD_1°C. Setting fan speed to 20%."
            set_fan_speed 0x14 # 20%
        else
            log "INFO" "Temperature normal. Setting fan speed to 10%."
            set_fan_speed 0xA # 10%
        fi
    fi

    # Wait A Set Time Before Rechecking
    sleep $CHECK_INTERVAL
done
