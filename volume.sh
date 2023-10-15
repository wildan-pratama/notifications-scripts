#!/usr/bin/env bash

result="Unknown"

if pgrep -x "pulseaudio" > /dev/null; then
	result="pulse"
elif pgrep -x "pipewire" > /dev/null; then
	result="pipewire"
else
    notify-send "Sound server: Unknown" "(Neither PulseAudio nor PipeWire)"
    exit
fi

get_volume () {
    amixer -D "$result" get Master | grep '%' | head -n 1 | cut -d '[' -f 2 | cut -d '%' -f 1
}

is_mute () {
    amixer -D "$result" get Master | grep '%' | grep -oE '[^ ]+$' | grep off > /dev/null
}

send_notification () {
    DIR=`dirname "$0"`
    volume=`get_volume`
    bar=$(seq -s "─" $(($volume/5)) | sed 's/[0-9]//g')
	
    if [ "$volume" = "0" ]; then
        icon_name="$HOME/.local/share/dunst/volume-mute.png"
    elif [  "$volume" -lt "30" ]; then
        icon_name="$HOME/.local/share/dunst/volume-low.png"
    elif [ "$volume" -lt "60" ]; then
        icon_name="$HOME/.local/share/dunst/volume-mid.png"
    else
        icon_name="$HOME/.local/share/dunst/volume-high.png"
	fi
	
	# Send the notification
	if [ "$volume" -lt "75" ]; then
        notify-send -i "$icon_name" "Audio Volume" "$volume $bar" --replace-id=555 -r 1
    else
        notify-send -u critical -i "$icon_name" "Audio Volume" "$volume $bar" --replace-id=555 -r 1
	fi
}

case $1 in
    up)
	# Set the volume on (if it was muted)
	amixer -D "$result" set Master on > /dev/null
	# Up the volume (+ 5%)
	amixer -D "$result" sset Master 5%+ > /dev/null
	#pactl set-sink-volume @DEFAULT_SINK@ +5%
	send_notification
	;;
    down)
	# Set the volume on (if it was muted)
	amixer -D "$result" set Master on > /dev/null
	# Down the volume (- 5%)
	amixer -D "$result" sset Master 5%- > /dev/null
	#pactl set-sink-volume @DEFAULT_SINK@ -5%
	send_notification
	;;
    mute)
	# Toggle mute
	amixer -D "$result" set Master 1+ toggle > /dev/null
	if is_mute ; then
	DIR=`dirname "$0"`
	notify-send -i "$HOME/.local/share/dunst/volume-mute.png" -u normal "Mute" -t 2000 --replace-id=555 -r 1 
	#notify-send -i "/usr/share/icons/Adwaita/32x32/status/audio-volume-muted-rtl-symbolic.symbolic.png" --replace-id=555 -u normal "Mute" -t 2000
	else
	    send_notification
	fi
    ;;
    mute-mic)
    pactl set-source-mute @DEFAULT_SOURCE@ toggle
    mic_status=$(pactl list sources | grep -A 10 RUNNING | grep -A 10 "input" | grep "Mute:" | awk '{print $2}')
    if [[ "$mic_status" == "yes" ]]; then
    notify-send -i "$HOME/.local/share/dunst/microphone.png" -u normal "Mute" -t 2000 --replace-id=555 -r 1 
	else
	notify-send -i "$HOME/.local/share/dunst/microphone-mute.png" -u normal "Mute" -t 2000 --replace-id=555 -r 1 
	fi
	;;
esac
