#!/usr/bin/env bash

EMOJIS=$(tail -n +2 ~/.config/rofi/emojis.csv | sed 's/^"//;s/"$//' | awk -F',' '{print $1 " " $2}')
CHOICE=$(echo "$EMOJIS" | rofi -dmenu -p "Pick emoji" -filter "" | awk '{print $1}')

[ -z "$CHOICE" ] && exit 1

if command -v wl-copy &>/dev/null; then
	echo -n "$CHOICE" | wl-copy
elif command -v xclip &>/dev/null; then
	echo -n "$CHOICE" | xclip -selection clipboard
else
	notify-send "Emoji Picker" "Couldn't copy to clipboard" && exit 1
fi

notify-send "Copied!" "$CHOICE copied to clipboard"
