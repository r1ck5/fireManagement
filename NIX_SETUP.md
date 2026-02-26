# Flutter 3.3.0 Development with Nix

This project uses **Nix** to provide a reproducible development environment for Flutter 3.3.0 with legacy dependencies. This approach eliminates the need for manual system environment configuration and ensures everyone working on the project has identical tooling.

## Why Nix for This Project?

- **Reproducibility**: Same environment on any machine running Nix
- **Isolation**: No system-wide dependency conflicts or version mismatches
- **Legacy Support**: Easily pin Flutter 3.3.0, JDK 11, and compatible Gradle versions
- **No Manual Configuration**: All dependencies are declaratively defined in `flake.nix`
- **Time Saving**: No more "it works on my machine" issues
- **Automatic Cleanup**: Dependencies don't pollute your system

## Prerequisites

### Required
- **Nix**: Single-user installation (already installed and available in zsh)
  - Verify: `zsh -c "nix --version"`
  - Should output: `nix (Nix) 2.33.3` or similar

### Optional but Highly Recommended
- **direnv**: For automatic environment activation on `cd` into project
  - Install: `curl -ifsSL https://direnv.net/install.sh | bash`
  - Enable in Nix: Edit `~/.config/nix/nix.conf` and add: `allow-dirty = true`
  - Setup in project: `direnv allow`

### Not Required (Flutter 3.3.0 will be provided by you)
- Nix does NOT provide Flutter 3.3.0 (due to licensing/age), but it provides all supporting tools
- You'll need to install Flutter 3.3.0 in `~/.flutter` (see Installation section)

## Quick Start

### 1. Install Flutter 3.3.0 (One-time Setup)

Since Nix doesn't provide Flutter directly, you need to install it once:

```bash
# Create Flutter directory
mkdir -p ~/.flutter

# Download Flutter 3.3.0
cd ~/.flutter
# For Linux x64
wget https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter-linux-3.3.0-stable.tar.gz
tar xzf flutter-linux-3.3.0-stable.tar.gz
rm flutter-linux-3.3.0-stable.tar.gz

# Or for macOS (Intel):
# wget https://storage.googleapis.com/flutter_infra_release/releases/stable/macos/flutter-macos-3.3.0-stable.zip
# unzip flutter-macos-3.3.0-stable.zip

# Verify installation
~/.flutter/bin/flutter --version
```

### 2. Enter the Development Environment

```bash
# Using nix develop (recommended)
cd /path/to/fireManagement
zsh -c 'nix develop'

# Alternative: Using direnv (if installed)
direnv allow
cd .  # Re-enter directory to trigger loading
```

### 3. Initialize Flutter and Get Dependencies

```bash
# Inside the Nix environment:
flutter doctor          # Check setup (may show warnings about system Flutter, OK to ignore)
flutter pub get         # Get dependencies
flutter pub run build_runner build --delete-conflicting-outputs  # Generate code
```

### 4. Run the App

```bash
# List available devices
flutter devices

# Run on connected device/emulator
flutter run

# Run on specific device
flutter run -d <device-id>
```

## Working with VSCode

### Option A: Manual (Recommended for Nix)

1. Open the project in VSCode
2. Open integrated terminal: `` Ctrl+` ``
3. Enter Nix environment: `zsh -c 'nix develop'`
4. Run Flutter commands normally
5. VSCode will detect Dart/Flutter extensions and work automatically

### Option B: Automatic with direnv

If you have direnv installed:

1. `direnv allow` in project root (one time)
2. Open project in VSCode
3. VSCode will automatically use environment when opening integrated terminal

### Recommended VSCode Extensions

Install these from the Extensions Marketplace:
- **Dart** (Dart-Code.dart-code) - Required
- **Flutter** (Dart-Code.flutter) - Recommended
- **Flutter Test** (Dart-Code.flutter-test) - Optional
- **GitLens** (eamodio.gitlens) - Optional but useful

Or: VSCode → Extensions → Click "Install Recommended Extensions"

## Project Structure

```
.
├── flake.nix                 # Nix flake configuration
├── .envrc                    # direnv configuration (optional)
├── setup-nix.sh              # Setup helper script
├── NIX_SETUP.md              # This file
├── .vscode/
│   ├── settings.json         # VSCode settings optimized for Flutter
│   ├── launch.json           # Debug configurations
│   └── extensions.json       # Recommended extensions
├── lib/                      # Dart/Flutter source code
├── android/                  # Android native code
├── ios/                      # iOS native code
└── pubspec.yaml              # Flutter dependencies
```

## Nix Configuration Details

### `flake.nix`
Defines the development shell with:

- **JDK 11**: For Android development (Flutter 3.3.0 compatible)
- **Android Tools**: adb, Gradle, platform-tools
- **Build Tools**: cmake, ninja, pkg-config
- **Environment Variables**: Properly configured for Flutter, Gradle, Android SDK

### `.envrc`
Automatically loads the Nix environment when you `cd` into the project (requires direnv).

## Common Tasks

### Install Dependencies
```bash
flutter pub get
```

### Generate Code (JSON serialization)
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### Watch Mode for Code Generation
```bash
flutter pub run build_runner watch
```

### Run Tests
```bash
flutter test
```

### Format Code
```bash
dart format lib/
```

### Analyze Code
```bash
dart analyze
```

### Build for Android
```bash
# Debug APK
flutter build apk

# Release APK
flutter build apk --release

# App Bundle (for Play Store)
flutter build appbundle --release
```

### List Available Devices
```bash
flutter devices
```

## Troubleshooting

### "flutter: command not found"
**Solution**: Make sure you're inside the Nix environment:
```bash
zsh -c 'cd /path/to/fireManagement && nix develop'
```

### "Java version mismatch"
**Solution**: The environment uses JDK 11, which is specified in `flake.nix`. Verify:
```bash
java -version
echo $JAVA_HOME
```

### "ANDROID_HOME not set"
**Solution**: This is automatically set in the Nix shell. If missing:
```bash
echo $ANDROID_HOME
# Should show ~/.android
```

### "gradle: command not found"
**Solution**: Gradle is provided by Nix. Ensure you're in the dev environment:
```bash
which gradle
```

### "PubCache issues"
**Solution**: The environment uses a local `.pub-cache` directory to avoid conflicts:
```bash
echo $PUB_CACHE
# Should show /path/to/fireManagement/.pub-cache
```

## Advanced Usage

### Create a Custom Nix Shell for Specific Tools

Edit `flake.nix` to add more tools under `buildInputs`:

```nix
buildInputs = with pkgs; [
  # ... existing packages ...
  postgresql    # example: add PostgreSQL
  redis         # example: add Redis
];
```

Then run: `nix flake update` and re-enter the shell.

### Use with CI/CD

For GitHub Actions or other CI:

```yaml
- name: Setup Nix
  uses: cachix/install-nix-action@v22

- name: Build Flutter
  run: nix develop --command bash -c "flutter pub get && flutter build apk"
```

## Notes

- **Flutter Version**: 3.3.0 (specified by system Flutter installation)
- **Java Version**: JDK 11 (via Nix)
- **Android API Level**: Configured in gradle.properties
- **Dart SDK**: Bundled with Flutter

## Further Reading

- [Nix Documentation](https://nixos.org/manual/nix/stable/)
- [Flutter Documentation](https://flutter.dev/docs)
- [direnv Documentation](https://direnv.net/)

## Support

If you encounter issues:
1. Check that Nix is properly installed: `zsh -c "nix --version"`
2. Delete `.pub-cache` and `.gradle` directories and try again
3. Ensure you're in the correct directory when running commands
4. Check `flake.lock` is present (created after first `nix develop`)
