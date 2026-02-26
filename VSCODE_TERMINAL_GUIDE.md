# VSCode Terminal Setup Guide - Nix Direnv Integration

## Overview

The project uses Nix flakes and direnv to automatically load the Flutter + Android development environment when you open a terminal in VSCode. This ensures consistent tooling across all team members.

## Expected Behavior

### First Terminal Open (After VSCode Restart)
- **Expected delay**: 15-30 seconds
- **What happens**: 
  - Direnv evaluates the flake
  - Nix creates/initializes the development environment
  - Flutter and Android tools are set up
  - Environment variables are exported

**Output looks like:**
```
direnv: loading ~/Projects/fireManagement/.envrc
direnv: using flake
Setting up Flutter 3.3.0 + Android dev environment...
✅ Flutter environment ready (fast path)
```

### Subsequent Terminal Opens
- **Expected delay**: 2-5 seconds
- **Why faster**: Environment is cached by direnv

### FHS Environment Startup Message

You may see:
```
FHS flutter-3.3.0-android-env-chrootenv:krs@krs-pc:~/Projects/fireManagement$
```

This is normal - it indicates you're in the Nix Filesystem Hierarchy Standard (FHS) environment that has Flutter and Android tools properly configured.

## Potential Issues & Solutions

### Issue 1: "error: opening lock file '/nix/var/nix/db/big-lock': Read-only file system"

**Cause**: Nix trying to update the lock file but encountering permissions issues (usually transient)

**Solution**: This error is temporary and usually resolves on the next terminal open. If it persists:
```bash
# Try reloading direnv
direnv reload

# Or clear direnv cache and reload
direnv allow
```

### Issue 2: "direnv is taking a while to execute"

**Cause**: First flake evaluation is slow due to network operations and environment setup

**Solution**: This is normal for first load. Wait 10-30 seconds for completion. Subsequent loads are much faster.

**To speed it up**: 
- Ensure you have a good internet connection
- Keep flake.lock file committed to git to prevent re-fetching inputs

### Issue 3: Flutter/Dart commands not found

**Cause**: Terminal opened outside the nix environment

**Solution**: Ensure you're in the project directory and direnv has loaded:
```bash
cd ~/Projects/fireManagement
direnv status  # Should show "Loaded RC path ..."
which flutter  # Should return a path in /nix/store
```

### Issue 4: VSCode shows "command not found" for flutter

**Cause**: VSCode's Dart extension didn't recognize the new PATH

**Solution**:
1. Close the terminal tab (⌘+W or Ctrl+W)
2. Open new terminal (Ctrl+`)
3. Wait for direnv to load (watch for the checkmark message)

## Optimization Tips

### Disable Direnv Logging (Cleaner Terminal)

The `.envrc` is configured to suppress Git warnings. If you want even quieter startup:

```bash
# Temporarily disable direnv output
export DIRENV_LOG_FORMAT=""
```

### Preload Environment in VSCode Settings

To ensure direnv runs immediately when VSCode opens, it's already configured in `.vscode/settings.json`:
```json
"terminal.integrated.defaultProfile.linux": "zsh"
```

### Cache Management

Direnv caches environments in `~/.cache/direnv/`. If you have persistent issues:

```bash
# Clear direnv cache (use carefully!)
rm -rf ~/.cache/direnv/

# Then reload
cd ~/Projects/fireManagement
direnv allow
```

## Manual Environment Loading

If direnv isn't working, you can manually load the environment:

```bash
cd ~/Projects/fireManagement
nix develop
```

Then use flutter normally:
```bash
flutter doctor
flutter run
```

## Verifying the Environment Works

Run these commands to verify everything is set up correctly:

```bash
# Should show Flutter 3.22.0+
flutter doctor -v

# Should show Android SDK 34
flutter doctor -v | grep Android

# Should be able to run Dart
dart --version

# Should find gradle
which gradle
```

## File Organization

- `.envrc` - Direnv configuration (loads the flake)
- `.vscode/settings.json` - VSCode-specific settings (includes terminal profile)
- `flake.nix` - Nix flake definition (defines the development environment)
- `flake.lock` - Lock file (ensures reproducible environments)

## Getting Help

If you encounter persistent issues:

1. Check direnv status: `direnv status`
2. Check flake validity: `nix flake check`
3. View detailed logs: `nix develop --print-build-logs`
4. Rebuild from scratch:
   ```bash
   direnv deny
   rm -rf ~/.cache/direnv
   direnv allow
   ```

## Performance Notes

- **First flake evaluation**: 15-30 seconds (one-time, environment cached)
- **Subsequent terminal opens**: 2-5 seconds
- **Flake rebuild**: Only needed when `flake.nix` or `flake.lock` changes
- **VSCode terminal startup**: Add 5-10 seconds to VSCode load time

This is expected behavior for a Nix-managed development environment with FHS support. The trade-off is a slower initial load for a reliable, reproducible environment.
