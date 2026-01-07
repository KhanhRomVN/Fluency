#!/bin/bash

echo "🔍 Checking for connected devices..."

# Get list of devices (excluding header and empty lines)
DEVICES=$(adb devices | grep -v "List of devices attached" | grep -v "^$" | awk '{print $1}')

# Convert to array
DEVICE_ARRAY=($DEVICES)
COUNT=${#DEVICE_ARRAY[@]}

if [ $COUNT -eq 0 ]; then
    echo "❌ No devices found. Please connect a device via USB."
    exit 1
fi

SELECTED_SERIAL=""

if [ $COUNT -eq 1 ]; then
    SELECTED_SERIAL=${DEVICE_ARRAY[0]}
    echo "✅ Found single device: $SELECTED_SERIAL"
else
    echo "📱 Multiple devices found:"
    for i in "${!DEVICE_ARRAY[@]}"; do
        # Get model name for better identification
        MODEL=$(adb -s "${DEVICE_ARRAY[$i]}" shell getprop ro.product.model 2>/dev/null)
        MODEL=${MODEL:-"Unknown"}
        echo "   [$((i+1))] ${DEVICE_ARRAY[$i]} ($MODEL)"
    done

    echo -n "👉 Please select a device (1-$COUNT): "
    read SELECTION

    # Validate input
    if [[ ! "$SELECTION" =~ ^[0-9]+$ ]] || [ "$SELECTION" -lt 1 ] || [ "$SELECTION" -gt "$COUNT" ]; then
        echo "❌ Invalid selection."
        exit 1
    fi

    # API returns 0-indexed array, user sees 1-indexed list
    INDEX=$((SELECTION-1))
    SELECTED_SERIAL=${DEVICE_ARRAY[$INDEX]}
fi

echo "🎯 Selected device: $SELECTED_SERIAL"

# Get the device IP address (wlan0 interface)
echo "🔍 Retrieving IP address for $SELECTED_SERIAL..."
DEVICE_IP=$(adb -s "$SELECTED_SERIAL" shell ip -f inet addr show wlan0 | grep "inet " | awk '{print $2}' | cut -d/ -f1)

if [ -z "$DEVICE_IP" ]; then
    echo "❌ Error: Could not detect device IP on wlan0."
    echo "   Please ensure:"
    echo "   1. The device is connected to the same WiFi network as this computer."
    echo "   2. WiFi is enabled on the device."
    exit 1
fi

echo "✅ Device IP: $DEVICE_IP"

echo "🔄 Restarting ADB in TCP/IP mode on port 5555..."
adb -s "$SELECTED_SERIAL" tcpip 5555

echo "⏳ Waiting 3 seconds for adb to restart..."
sleep 3

echo "🔌 Connecting to device wirelessly..."
adb connect "$DEVICE_IP:5555"

echo "📊 Verifying connection..."
adb devices

echo "🎉 Done! You can now unplug the USB cable if desired."
