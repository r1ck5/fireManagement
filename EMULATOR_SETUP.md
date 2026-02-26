# Emulator Setup & Troubleshooting Guide

## Quick Start

### Step 1: Enter the Nix environment
```bash
nix develop
```

### Step 2: Launch the emulator (inside nix develop)
```bash
bash emulator-wrapper.sh
```

Or if you want to use the Nix-provided `run-emulator` command, run this interactively:
```bash
nix develop
# Then in the shell:
run-emulator
```

## Understanding the Vulkan Error

The error you encountered was:
```
ERROR | Your GPU cannot be used for hardware rendering.
ERROR | emuglConfig_get_vulkan_hardware_gpu_support_info: Failed to create vulkan instance.
Error: [VK_ERROR_INCOMPATIBLE_DRIVER] -9
```

This is **very common on NixOS** and other non-standard Linux distributions because:
1. The emulator's bundled Vulkan loader can't find compatible GPU drivers
2. Nix's FHS environment can't properly expose GPU drivers to the emulator
3. This is NOT a problem with your setup - it's a known compatibility issue

### Solution: Software Rendering

The emulator can still run perfectly fine using **software rendering**. It's slower (30-50% performance), but:
- ✅ Works reliably across all systems
- ✅ Fully functional for development and testing
- ✅ GPU-accelerated rendering isn't needed for typical Flutter development

## Running the Emulator

### Option 1: Using the wrapper script (RECOMMENDED)
```bash
cd /home/krs/Projects/fireManagement
nix develop --command bash emulator-wrapper.sh
```

### Option 2: Interactive mode
```bash
nix develop
# Then run:
run-emulator
```

### Option 3: Direct command
```bash
nix develop --command bash -c '\
  export ANDROID_HOME=$PWD/.android/sdk && \
  $ANDROID_HOME/emulator/emulator -avd android_emulator \
    -gpu swiftshader_indirect \
    -no-snapshot -no-metrics
'
```

## What You'll See

When the emulator starts successfully, you'll see:
```
Launching Android emulator...
DISPLAY: :0

📊 Using software rendering (or GPU acceleration if detected)
🚀 Starting emulator with -gpu swiftshader_indirect

INFO | Android emulator version 36.5.5.0 (build_id 14911367)
INFO | Graphics backend: gfxstream
INFO | Found systemPath /home/krs/Projects/fireManagement/.android/sdk/system-images/...
INFO | Storing crashdata in: /tmp/android-krs/emu-crash-36.5.5.db
INFO | Initializing gfxstream backend
```

Then the emulator window should appear on your display.

## Emulator Not Starting?

### Error: "DISPLAY is not set"
**Solution**: Make sure you're running in a graphical environment with X11 or Wayland.
```bash
# Check your DISPLAY
echo $DISPLAY

# If empty, export it:
export DISPLAY=:0
```

### Error: "emulator: command not found"
**Solution**: Make sure you're inside `nix develop`:
```bash
nix develop
bash emulator-wrapper.sh
```

### Emulator window doesn't appear
**For X11**:
```bash
xhost +local:
```

**For Wayland** (auto-handled by the wrapper):
```bash
export WAYLAND_DISPLAY=wayland-0
# The wrapper will auto-select XWayland
```

### Emulator crashes immediately
1. Check if the AVD was created: `ls ~/.android/avd/`
2. Re-enter the environment: `exit` then `nix develop` again
3. Check system resources: `free -h` (emulator needs ~3GB RAM)

## Performance Tips

### If emulator is too slow:
1. Allocate more RAM to emulator (edit `~/.android/avd/android_emulator.avd/config.ini`):
   ```ini
   hw.ramSize=4096
   ```

2. Enable snapshot mode (trades disk space for startup speed):
   ```bash
   # First boot:
   emulator -avd android_emulator -no-snapshot
   # Then use snapshots:
   emulator -avd android_emulator
   ```

### Rebuild with fresh AVD:
```bash
rm -rf ~/.android/avd/android_emulator.avd
nix develop  # Will recreate AVD
```

## Running the App on Emulator

Once the emulator is running, in a **new terminal** (NOT inside nix develop):
```bash
cd /home/krs/Projects/fireManagement
nix develop --command flutter run
```

The emulator and development tools are now ready to use!

---

**Note**: The software rendering fallback ensures the emulator works everywhere. GPU-accelerated rendering requires specific driver configurations that may not be available in containerized/Nix environments.
