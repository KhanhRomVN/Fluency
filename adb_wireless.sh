#!/bin/bash

# Required: Only one device should be connected via USB initially for this script to work reliably,
# or you must specify the device ID manually if there are multiple.
# This script assumes one device connected via USB.

echo "🔍 Checking for connected devices..."
adb devices

# Get the device IP address (wlan0 interface)
# We grep for 'inet ' to find IPv4, take the second column, and strip the subnet mask
DEVICE_IP=$(adb shell ip -f inet addr show wlan0 | grep "inet " | awk '{print $2}' | cut -d/ -f1)

if [ -z "$DEVICE_IP" ]; then
    echo "❌ Error: Could not detect device IP on wlan0."
    echo "   Please ensure:"
    echo "   1. The device is connected via USB."
    echo "   2. The device is connected to the same WiFi network as this computer."
    echo "   3. USB debugging is enabled."
    exit 1
fi

echo "✅ Device found with IP: $DEVICE_IP"

echo "🔄 Restarting ADB in TCP/IP mode on port 5555..."
adb tcpip 5555

echo "⏳ Waiting 3 seconds for adb to restart..."
sleep 3

echo "🔌 Connecting to device wirelessly..."
adb connect "$DEVICE_IP:5555"

echo "📊 Verifying connection..."
adb devices

echo "🎉 Done! You can now unplug the USB cable."
