#!/bin/bash

function main() {
    # Pipewire / PulseAudio
    SOURCE=$(pw-record --list-targets | sed -n 's/^*.*"\(.*\)" prio=.*$/\1/p' | head -n1)
    SINK=$(pw-play --list-targets | sed -n 's/^*.*"\(.*\)" prio=.*$/\1/p' | head -n1)
    
    if [ -z "$SINK" ]; then
        echo "No sink found"
        exit 1
    fi

    VOLUME=$(pactl list sinks | grep -A 15 "Name: $SINK" | grep 'Volume:' | head -n1 | awk '{print $5}' | tr -d '%')
    IS_MUTED=$(pactl list sinks | grep -A 15 "Name: $SINK" | grep 'Mute:' | awk '{print $2}')

    action=$1
    if [ "$action" == "up" ]; then
        pactl set-sink-volume @DEFAULT_SINK@ +10%
    elif [ "$action" == "down" ]; then
        pactl set-sink-volume @DEFAULT_SINK@ -10%
    elif [ "$action" == "mute" ]; then
        pactl set-sink-mute @DEFAULT_SINK@ toggle
    else
        if [ "$IS_MUTED" == "yes" ]; then
            echo " ${SOURCE} |  MUTED ${SINK}"
        else
            echo " ${SOURCE} |  ${VOLUME}% ${SINK}"
        fi
    fi
}

main "$@"
