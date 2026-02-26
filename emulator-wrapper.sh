#!/bin/bash
# Simple wrapper to test the emulator with software rendering fallback

set -e

if [ -z "$DISPLAY" ]; then
    echo "ERROR: DISPLAY is not set. Please run this in a graphical environment."
    exit 1
fi

ANDROID_HOME="$PWD/.android/sdk"
export ANDROID_HOME
export ANDROID_SDK_ROOT="$ANDROID_HOME"
export PATH="$ANDROID_HOME/bin:$ANDROID_HOME/platform-tools:$PATH"

echo "Launching Android emulator..."
echo "DISPLAY: $DISPLAY"
echo ""

# Determine GPU mode
if [ -f "/run/opengl-driver/lib/libvulkan.so" ] || [ -f "/run/opengl-driver/lib/libvulkan.so.1" ]; then
    echo "📊 NVIDIA driver detected"
    GPU_MODE="-gpu host"
elif lspci 2>/dev/null | grep -q "VGA\|3D"; then
    echo "📊 Graphics card detected"
    GPU_MODE="-gpu host"
else
    echo "📊 Using software rendering"
    GPU_MODE="-gpu swiftshader_indirect"
fi

echo "🚀 Starting emulator with $GPU_MODE"
echo ""

exec "$ANDROID_HOME/emulator/emulator" -avd android_emulator \
    $GPU_MODE \
    -no-snapshot \
    -no-snapshot-load \
    -no-snapshot-save \
    -port 5554 \
    -grpc 8554 \
    -no-metrics 2>&1
