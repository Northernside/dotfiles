#!/bin/bash

function get_status() {
    SINK=$(pactl info | grep "Default Sink" | awk '{print $3}')
    SINK_NICENAME="Default Output"
    if [[ "$SINK" == *.* ]]; then
        SINK_NICENAME=$(echo "$SINK" | awk -F. '{print $NF}')
    fi

    if [ -z "$SINK" ]; then
        echo "No sink found"
        return
    fi

    VOLUME=$(pactl list sinks | grep -A 15 "Name: $SINK" | grep 'Volume:' | head -n1 | awk '{print $5}' | tr -d '%')
    IS_MUTED=$(pactl list sinks | grep -A 15 "Name: $SINK" | grep 'Mute:' | awk '{print $2}')

    if [ "$IS_MUTED" == "yes" ]; then
        echo "$SINK_NICENAME MUTED"
    else
        echo "$SINK_NICENAME ${VOLUME}%"
    fi
}

function control_volume() {
    case "$1" in
        up)
            pactl set-sink-volume @DEFAULT_SINK@ +5%
            ;;
        down)
            pactl set-sink-volume @DEFAULT_SINK@ -5%
            ;;
    esac
}

if [[ "$1" == "up" || "$1" == "down" ]]; then
    control_volume "$1"
    exit 0
fi

get_status
