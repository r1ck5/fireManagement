# Direnv + Nix Setup Guide

## Problem Fixed

After reinstalling direnv, you were getting errors:
- `.profile` parse error near `|` on line 486
- `nix: /usr/lib/libstdc++.so.6: version 'CXXABI_1.3.15' not found`
- `direnv` hanging

## Solution Implemented

Updated `.envrc` to:
1. Ensure `/nix/var/nix/profiles/default/bin` is in PATH
2. Set proper `LD_LIBRARY_PATH` for nix libraries
3. This fixes the C++ ABI incompatibility issue

## How to Use

### Option 1: Auto-load with direnv (RECOMMENDED)

Just `cd` into the project directory:
```bash
cd ~/Projects/fireManagement
# direnv automatically loads the environment!
```

Then run Flutter commands directly:
```bash
flutter run                # Run app
flutter build apk          # Build APK
flutter test               # Run tests
```

### Option 2: Manual `nix develop`

```bash
cd ~/Projects/fireManagement
nix develop
# Then inside the shell:
flutter run
run-emulator
```

### Option 3: Run single command with nix

```bash
nix develop --command flutter run
nix develop --command bash emulator-wrapper.sh
```

## Verification

### Test direnv loads correctly:
```bash
cd ~/Projects/fireManagement
direnv status
```

You should see:
```
Loaded /home/krs/Projects/fireManagement/.envrc
```

### Test nix is available:
```bash
nix --version
```

Should show: `nix (Nix) 2.33.3`

### Test Flutter:
```bash
flutter doctor
```

Should show ✓ for most components (Android SDK, Flutter, etc.)

## What Changed in `.envrc`

Before:
```bash
use flake
```

After:
```bash
# Ensure nix is available in PATH for direnv
export PATH="/nix/var/nix/profiles/default/bin:${PATH}"

# Fix C++ library compatibility for nix
# This resolves CXXABI_1.3.15 errors when direnv loads nix
if [ -d "/nix/store" ]; then
  # Find the nix lib directory and add it to LD_LIBRARY_PATH
  NIX_LIB=$(ls -d /nix/store/*-nix-*/lib 2>/dev/null | head -1)
  if [ -d "$NIX_LIB" ]; then
    export LD_LIBRARY_PATH="$NIX_LIB:${LD_LIBRARY_PATH}"
  fi
fi

# Use the flake
use flake
```

## Troubleshooting

### Direnv not loading automatically

Make sure your shell has direnv hooked:
```bash
# For zsh, check ~/.zshrc has:
eval "$(direnv hook zsh)"

# For bash, check ~/.bashrc has:
eval "$(direnv hook bash)"
```

### Getting "blocked" error

Run:
```bash
cd ~/Projects/fireManagement
direnv allow
```

### Still getting CXXABI errors

Try reloading:
```bash
cd ~/Projects/fireManagement
direnv reload
```

## Tips

- **Auto-load**: direnv automatically activates the environment when you `cd` into the project
- **Auto-unload**: When you `cd` out of the project, the environment is deactivated
- **Quick switching**: Easy to switch between different projects with their own environments
- **No source needed**: Unlike `source <(nix develop)`, direnv handles everything automatically

---

**Status**: ✅ Direnv + Nix compatibility fixed!
