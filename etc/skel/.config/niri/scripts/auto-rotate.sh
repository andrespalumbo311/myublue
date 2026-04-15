#!/bin/bash
# Niri Auto-Rotate - X390 Yoga - FINAL CALIBRATED
SENSOR_DIR="/sys/bus/iio/devices/iio:device2"
OUTPUT="eDP-1"
TABLET_MODE="/sys/devices/platform/thinkpad_acpi/hotkey_tablet_mode"
APPLY_WALLPAPER="$HOME/.config/niri/scripts/niri-apply-wallpaper.sh"

# Find the correct iio device for accelerometer
SENSOR_DIR=""
for dev in /sys/bus/iio/devices/iio:device*; do
    if [ -f "$dev/in_accel_x_raw" ]; then
        SENSOR_DIR="$dev"
        if grep -q "accel" "$dev/name" 2>/dev/null; then
             break
        fi
    fi
done

if [ -z "$SENSOR_DIR" ]; then
    echo "No accelerometer found, defaulting to device0"
    SENSOR_DIR="/sys/bus/iio/devices/iio:device0"
fi

THRESHOLD=250000

get_rot() {
    niri msg -j outputs | jq -r ".\"$OUTPUT\".logical.transform" | tr '[:upper:]' '[:lower:]'
}

apply_rot() {
    local target=$1
    local current=$(get_rot)
    if [ "$target" != "$current" ]; then
        niri msg output "$OUTPUT" transform "$target"
        sleep 0.5
        [ -f "$APPLY_WALLPAPER" ] && bash "$APPLY_WALLPAPER"
    fi
}

while true; do
    # Laptop mode check
    if [ "$(cat "$TABLET_MODE" 2>/dev/null)" == "0" ]; then
        apply_rot "normal"
        sleep 2
        continue
    fi

    # Read sensor
    x=$(cat "$SENSOR_DIR/in_accel_x_raw" 2>/dev/null || echo 0)
    y=$(cat "$SENSOR_DIR/in_accel_y_raw" 2>/dev/null || echo 0)
    
    target="normal"
    if [ "$y" -lt -"$THRESHOLD" ]; then
        target="normal"
    elif [ "$y" -gt "$THRESHOLD" ]; then
        target="180"
    fi
    # X logic overrides if dominantly on the side
    if [ "$x" -gt "$THRESHOLD" ]; then
        target="90"
    elif [ "$x" -lt -"$THRESHOLD" ]; then
        target="270"
    fi

    apply_rot "$target"
    sleep 1
done
