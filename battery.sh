#!/usr/bin/env bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# Check if 'acpi' or 'upower' command is available
getinfo () {
    if command -v acpi &> /dev/null; then
        battery_info=$(acpi -b)
        battery_percent=$(echo "$battery_info" | grep -P -o '[0-9]+(?=%)')
        if [[ $battery_info == *"Charging"* ]]; then
            charging="yes"
        elif [[ $battery_info == *"on-line"* ]]; then
            charging="no"
        else
            plug="yes"
        fi
    elif command -v upower &> /dev/null; then
        battery_info=$(upower -i $(upower -e | grep 'BAT'))
        battery_percent=$(echo "$battery_info" | grep "percentage" | awk '{print $2}' | tr -d '%')
        charging_state=$(echo "$battery_info" | grep "state" | awk '{print $2}')
        if [[ $charging_state == "charging" ]]; then
            charging="yes"
        elif [[ $charging_state == "discharging" ]]; then
            charging="no"
        else
            plug="yes"
        fi
    else
        notify-send "Error" "Neither 'acpi' nor 'upower' is available. Install one of them."
        exit 1
    fi
}

while true; do

    plug="no"
    getinfo

    unlow () {
        if [ -f "$DIR/.low" ]; then
            rm -rf $DIR/.low
        fi
        if [ -f "$DIR/.15" ]; then
            rm -rf $DIR/.15
        fi
        if [ -f "$DIR/.10" ]; then
            rm -rf $DIR/.10
        fi
        if [ -f "$DIR/.5" ]; then
            rm -rf $DIR/.5
        fi
    }
    notifylow () {
        notify-send -i "$HOME/.local/share/dunst/battery-low.png" -u critical "Battery" "battery low ($battery_percent%)" -t 5000 --replace-id=555
    }

    if [ "$plug" = "yes" ]; then
        if [ -n "$battery_percent" ]; then
            if [ "$battery_percent" -ge "21" ]; then
                unlow
            fi
        fi
        if [ ! -f "$DIR/.plug" ]; then
            touch $DIR/.plug
            notify-send -i "$HOME/.local/share/dunst/power-plugin.png" -u normal "Battery" "Plugin not charging.." -t 5000 --replace-id=555 
        fi
    fi
    
    if [ "$plug" = "no" ]; then
        if [ -f "$DIR/.plug" ]; then
            rm -rf $DIR/.plug
            notify-send -i "$HOME/.local/share/dunst/power-plugin.png" -u normal "Battery" "Plugin Disconnected" -t 5000 --replace-id=555 
        fi
    fi
            
    if [ "$charging" = "yes" ]; then
        if [ -n "$battery_percent" ]; then
            if [ "$battery_percent" -ge "21" ]; then
                unlow
            fi
        fi
        if [ ! -f "$DIR/.charging" ]; then
            touch $DIR/.charging
            notify-send -i "$HOME/.local/share/dunst/charging.png" -u normal "Battery" "Charging Connected ($battery_percent%)" -t 5000 --replace-id=555 
        fi    
	fi
    
    if [ "$charging" = "no" ]; then
        if [ -f "$DIR/.charging" ]; then
            rm -rf $DIR/.charging
            notify-send -i "$HOME/.local/share/dunst/charging.png" -u normal "Battery" "Charging Disconnected" -t 5000 --replace-id=555 
        fi
    fi
    

    if [ -n "$battery_percent" ]; then
        if [ "$battery_percent" = "20" ]; then
            if [ ! -f "$DIR/.low" ]; then
                touch $DIR/.low
                notifylow
            fi
        fi
        
        if [ "$battery_percent" = "15" ]; then
            if [ ! -f "$DIR/.15" ]; then
                touch $DIR/.15
                notifylow
            fi
        fi
        
        if [ "$battery_percent" = "10" ]; then
            if [ ! -f "$DIR/.10" ]; then
                touch $DIR/.10
                notifylow
            fi
        fi
        
        if [ "$battery_percent" = "5" ]; then
            if [ ! -f "$DIR/.5" ]; then
                touch $DIR/.5
                notifylow
            fi
        fi

        if [ "$battery_percent" = "21" ]; then
            unlow
        fi
    
        if [ "$battery_percent" = "100" ]; then
            if [ ! -f "$DIR/.100" ]; then
                touch $DIR/.100
                notify-send -i "$HOME/.local/share/dunst/percentage.png" -u normal "Battery" "Battery full ($battery_percent%)" -t 5000 --replace-id=555
            fi
        fi

        if [ "$battery_percent" -lt "100" ]; then
            if [ -f "$DIR/.100" ]; then
                rm -rf $DIR/.100
            fi
        fi
    fi
    
    sleep 1
done