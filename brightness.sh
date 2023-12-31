#!/usr/bin/env bash

get_brightness () {
  brightnessctl get
}

send_notification () {
	DIR=$(dirname "$0")
	brightness=$(get_brightness)
	bar=$(seq -s "─" $(($brightness/5)) | sed 's/[0-9]//g')
  	
	if [ "$brightness" -lt "21" ]; then
        icon_name="$HOME/.local/share/dunst/brightness-20.png"
    elif [ "$brightness" -lt "41" ]; then
        icon_name="$HOME/.local/share/dunst/brightness-40.png"
    elif [ "$brightness" -lt "61" ]; then
        icon_name="$HOME/.local/share/dunst/brightness-60.png"
    elif [ "$brightness" -lt "81" ]; then
        icon_name="$HOME/.local/share/dunst/brightness-80.png"
    else
        icon_name="$HOME/.local/share/dunst/brightness-100.png"
	fi
	
	# Send the notification
	notify-send -i "$icon_name" "Brightness" "$brightness $bar" --replace-id=555 -r 1 
}

case $1 in
  up)
    # increase the backlight by 5%
    brightnessctl set +5%
    send_notification
    ;;
  down)
    # decrease the backlight by 5%
    brightnessctl set 5%-
    send_notification
    ;;
esac
