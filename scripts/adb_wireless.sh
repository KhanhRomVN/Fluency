#!/bin/bash

echo "🔍 Scanning for Android devices on local network..."
echo "⚠️  Note: This requires ADB wireless debugging to be enabled on the device"
echo ""

# Get local network IP range
LOCAL_IP=$(ip route get 1 | awk '{print $7; exit}')
if [ -z "$LOCAL_IP" ]; then
    LOCAL_IP=$(hostname -I | awk '{print $1}')
fi

if [ -z "$LOCAL_IP" ]; then
    echo "❌ Could not determine local IP address"
    exit 1
fi

# Extract network prefix (e.g., 192.168.1 from 192.168.1.100)
NETWORK_PREFIX=$(echo $LOCAL_IP | cut -d. -f1-3)
echo "📡 Your IP: $LOCAL_IP"
echo "🌐 Scanning network: $NETWORK_PREFIX.0/24"
echo ""

# Array to store found devices
declare -a FOUND_DEVICES
declare -a DEVICE_MODELS

# Scan common ADB wireless ports (5555, 5556, 5557)
PORTS=(5555 5556 5557)
SCAN_COUNT=0

echo "🔎 Scanning for ADB devices (this may take 30-60 seconds)..."

for i in {1..254}; do
    IP="$NETWORK_PREFIX.$i"
    
    # Skip own IP
    if [ "$IP" == "$LOCAL_IP" ]; then
        continue
    fi
    
    # Show progress every 50 IPs
    ((SCAN_COUNT++))
    if [ $((SCAN_COUNT % 50)) -eq 0 ]; then
        echo "   ... scanned $SCAN_COUNT/254 addresses"
    fi
    
    for PORT in "${PORTS[@]}"; do
        # Quick TCP port check (timeout 0.3s)
        (echo >/dev/tcp/$IP/$PORT) >/dev/null 2>&1 &
        PID=$!
        
        # Wait max 0.3 seconds
        ( sleep 0.3; kill $PID 2>/dev/null ) &
        KILLER=$!
        
        wait $PID 2>/dev/null
        EXIT_CODE=$?
        
        kill $KILLER 2>/dev/null
        wait $KILLER 2>/dev/null
        
        if [ $EXIT_CODE -eq 0 ]; then
            # Port is open, try to connect with adb
            CONNECT_RESULT=$(adb connect $IP:$PORT 2>&1)
            
            if echo "$CONNECT_RESULT" | grep -q "connected"; then
                # Try to get device model
                MODEL=$(adb -s $IP:$PORT shell getprop ro.product.model 2>/dev/null | tr -d '\r')
                MANUFACTURER=$(adb -s $IP:$PORT shell getprop ro.product.manufacturer 2>/dev/null | tr -d '\r')
                ANDROID_VERSION=$(adb -s $IP:$PORT shell getprop ro.build.version.release 2>/dev/null | tr -d '\r')
                
                if [ -n "$MODEL" ]; then
                    FOUND_DEVICES+=("$IP:$PORT")
                    DEVICE_MODELS+=("$MANUFACTURER $MODEL (Android $ANDROID_VERSION)")
                    echo "   ✅ Found: $IP:$PORT - $MANUFACTURER $MODEL"
                fi
                
                # Disconnect to clean up
                adb disconnect $IP:$PORT >/dev/null 2>&1
            fi
        fi
    done
done

echo ""
echo "📊 Scan complete!"
echo ""

# Check results
COUNT=${#FOUND_DEVICES[@]}

if [ $COUNT -eq 0 ]; then
    echo "❌ No Android devices found on the network."
    echo ""
    echo "💡 Troubleshooting tips:"
    echo "   1. Enable 'Wireless debugging' in Developer Options on your Android device"
    echo "   2. Make sure device and computer are on the same WiFi network"
    echo "   3. Some devices require pairing first (Android 11+)"
    echo "   4. Check if firewall is blocking ADB ports (5555-5557)"
    exit 1
fi

SELECTED_DEVICE=""

if [ $COUNT -eq 1 ]; then
    SELECTED_DEVICE=${FOUND_DEVICES[0]}
    echo "✅ Found 1 device: ${DEVICE_MODELS[0]}"
    echo "   Address: $SELECTED_DEVICE"
else
    echo "📱 Found $COUNT devices:"
    for i in "${!FOUND_DEVICES[@]}"; do
        echo "   [$((i+1))] ${FOUND_DEVICES[$i]} - ${DEVICE_MODELS[$i]}"
    done
    echo ""
    echo -n "👉 Please select a device (1-$COUNT): "
    read SELECTION

    # Validate input
    if [[ ! "$SELECTION" =~ ^[0-9]+$ ]] || [ "$SELECTION" -lt 1 ] || [ "$SELECTION" -gt "$COUNT" ]; then
        echo "❌ Invalid selection."
        exit 1
    fi

    INDEX=$((SELECTION-1))
    SELECTED_DEVICE=${FOUND_DEVICES[$INDEX]}
fi

echo ""
echo "🔌 Connecting to $SELECTED_DEVICE..."
adb connect "$SELECTED_DEVICE"

echo ""
echo "📊 Connected devices:"
adb devices

echo ""
echo "🎉 Done! Device connected wirelessly."
echo ""
echo "💡 Useful commands:"
echo "   adb devices          - List connected devices"
echo "   adb -s $SELECTED_DEVICE shell  - Open shell on this device"
echo "   adb disconnect $SELECTED_DEVICE  - Disconnect this device"