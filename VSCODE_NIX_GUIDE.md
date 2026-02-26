# Using Nix with VSCode and Terminals

## What We Just Fixed

Your Nix installation needed experimental features enabled. The file `/home/krs/.config/nix/nix.conf` now has:

```ini
experimental-features = nix-command flakes
allow-import-from-derivation = true
```

This allows Nix flakes to work properly.

---

## How to Use Nix for Development

### **Method 1: Manual Terminal Entry (Simplest)**

This is the most straightforward approach for daily development.

#### Step 1: Open VSCode
```bash
code /home/krs/Projects/fireManagement
```

#### Step 2: Open Integrated Terminal
Press `` Ctrl+` `` to open the terminal at the bottom of VSCode.

#### Step 3: Enter Nix Environment
```bash
nix develop
```

You'll see the environment banner:
```
╔════════════════════════════════════════════════════════════╗
║  Flutter 3.3.0 Fire Management App - Nix Dev Environment  ║
║  System: x86_64-linux                           
╚════════════════════════════════════════════════════════════╝

📦 Java Configuration:
   openjdk version "11.0.19" 2023-04-18

📦 Build Tools:
   Gradle: Welcome to Gradle 8.4!
   CMake: cmake version 3.27.7
   Ninja: 1.11.1
```

#### Step 4: Run Flutter Commands
```bash
# Install dependencies
flutter pub get

# Generate code for models
flutter pub run build_runner build --delete-conflicting-outputs

# Run app on device
flutter run

# Analyze code (linting now works!)
dart analyze

# Format code
dart format lib/

# Or use Makefile shortcuts
make help
make run
make build-release
```

**Status:**
- ✅ Java 11 available
- ✅ Android tools configured
- ✅ Gradle working
- ✅ Flutter 3.3.0 available (once installed at ~/.flutter)
- ✅ Linting enabled (dart analyze works)

---

### **Method 2: With direnv (Automatic)**

This automatically loads the Nix environment when you `cd` into the project.

#### Step 1: Check if direnv is installed
```bash
which direnv
```

If not installed:
```bash
# Linux
curl -ifsSL https://direnv.net/install.sh | bash

# macOS
brew install direnv
```

#### Step 2: Add direnv hook to zsh
Edit `~/.zshrc` and add at the end:
```bash
eval "$(direnv hook zsh)"
```

Then reload shell:
```bash
exec zsh
```

#### Step 3: Allow direnv for this project
```bash
cd /home/krs/Projects/fireManagement
direnv allow
```

#### Step 4: Usage - Just cd into project!
```bash
cd /home/krs/Projects/fireManagement
# 🎉 Automatically loads Nix environment!

# Now you can immediately run:
flutter run
dart analyze
make build-release

# When you leave project directory, environment unloads
cd ~
# Environment is gone, clean system
```

**Advantages:**
- ✅ Automatic - no manual commands needed
- ✅ All new terminals auto-load
- ✅ VSCode integrated terminal auto-loads
- ✅ Very smooth workflow

**Disadvantages:**
- ⚠️ Requires direnv installation
- ⚠️ Slightly slower (checks on every `cd`)

---

## VSCode Configuration for Linting

Now that Nix is working, follow these steps to fix VSCode linting:

### Option 1: Recommended - Use Nix Environment in VSCode

#### In VSCode Terminal:
1. Open terminal: `` Ctrl+` ``
2. Type: `nix develop`
3. Wait for environment to load (see banner)
4. Open or edit a Dart file
5. VSCode Dart extension will detect the environment and enable linting

The Dart extension will find:
- ✅ Dart SDK (from Flutter 3.3.0)
- ✅ Analyzer (dart analyze)
- ✅ Formatter (dart format)

### Option 2: Install Dart/Flutter Extensions

1. In VSCode, press `Ctrl+Shift+X` to open Extensions
2. Search "Dart Code"
3. Install both:
   - **Dart** (Dart-Code.dart-code) - Required
   - **Flutter** (Dart-Code.flutter) - Recommended
4. Restart VSCode

Once installed and you're inside `nix develop`, the extension will automatically detect tools.

---

## Practical Examples

### Example 1: Daily Development Workflow

```bash
# Morning
$ code /home/krs/Projects/fireManagement

# In VSCode Terminal (Ctrl+`)
$ nix develop

# See banner confirming environment setup

# Now work freely
$ flutter pub get
$ flutter run

# Edit code in VSCode editor
# Flutter hot-reloads automatically
# Linting works in real-time
# Code completion works
```

### Example 2: Building Release APK

```bash
# In project directory terminal
$ nix develop

# Build APK
$ make build-release

# Output: build/app/outputs/flutter-apk/app-release.apk

# Or manually:
$ flutter build apk --release
```

### Example 3: Code Generation (Models with @JsonSerializable)

```bash
$ nix develop

# Option 1: One-time generation
$ make generate
# or
$ flutter pub run build_runner build --delete-conflicting-outputs

# Option 2: Watch for changes
$ make watch-generate
# Keep terminal open, regenerates automatically when files change
```

### Example 4: Parallel Tasks

Terminal 1 (Development):
```bash
$ nix develop
$ flutter run        # App runs with hot-reload
```

Terminal 2 (Code generation):
```bash
$ nix develop
$ make watch-generate  # Auto-generates code on file changes
```

Terminal 3 (Testing):
```bash
$ nix develop
$ flutter test
```

---

## Quick Reference

### Commands Inside `nix develop`

```bash
# Get help on all commands
make help

# Dependency management
flutter pub get           # Download dependencies
flutter pub upgrade       # Upgrade dependencies

# Code generation
make generate             # Generate .g.dart files
make watch-generate       # Watch and auto-generate

# Development
flutter run               # Run app
flutter devices           # List connected devices

# Testing & Quality
flutter test              # Run tests
dart analyze              # Lint code
dart format lib/          # Format code

# Building
make build-debug          # Build debug APK
make build-release        # Build release APK
make build-appbundle      # Build for Play Store

# Cleanup
make clean                # Remove build artifacts
```

### Outside `nix develop` (System Shell)

```bash
# Only these work:
nix develop               # Enter environment
make install-flutter      # Install Flutter 3.3.0
make env                  # Enter environment (alias for nix develop)
make help                 # Show Makefile commands
```

---

## Important Paths

When inside `nix develop`:

```bash
echo $JAVA_HOME              # JDK 11 location
echo $ANDROID_HOME          # Android SDK (~/.android)
echo $FLUTTER_ROOT          # Flutter location (~/.flutter)
echo $PUB_CACHE             # Local pub cache
echo $GRADLE_USER_HOME      # Local gradle cache
which flutter               # Flutter location
which dart                  # Dart SDK location
```

All caches are local to project, so multiple projects don't interfere.

---

## Troubleshooting

### "nix: command not found"
**Solution:** You're in bash, not zsh. VSCode terminal defaults to bash.

In VSCode, type:
```bash
zsh
nix develop
```

Or permanently change VSCode terminal to zsh:
1. Ctrl+Shift+P → "Terminal: Select Default Profile"
2. Choose "zsh"

### "flutter: command not found" in VSCode terminal
**Solution:** You haven't entered `nix develop` yet.

```bash
nix develop
flutter --version
```

### Linting still disabled in VSCode
**Solution:** Wait for Dart extension to load (30 seconds).

1. Enter `nix develop`
2. Open a Dart file
3. Wait for extension to detect environment
4. Hover over code - should show type hints

If still not working:
- Restart VSCode: Ctrl+Shift+P → "Developer: Reload Window"
- Check extension is installed: Ctrl+Shift+X → Search "Dart Code"

### "JAVA_HOME not set"
**Solution:** You're outside `nix develop`. It only works inside:

```bash
nix develop
echo $JAVA_HOME  # Now shows path
```

### Multiple flutter processes running
**Solution:** Stop them properly:

```bash
flutter run      # Terminal 1
# Press Ctrl+C to stop gracefully

# Then in Terminal 2:
flutter run      # Starts fresh
```

---

## Which Method Should You Use?

| Scenario | Recommendation |
|----------|-----------------|
| Learning/Testing Nix | **Method 1** (Manual) |
| Daily development | **Method 1** or **Method 2** |
| Most automated experience | **Method 2** (direnv) |
| Quick one-off builds | **Method 1** in one terminal |
| Multiple tasks in parallel | **Method 1** with multiple terminals |

**My recommendation:** Start with **Method 1** (simple and transparent), then upgrade to **Method 2** (direnv) once comfortable.

---

## Next Steps

1. ✅ Nix is now configured with experimental features
2. Open VSCode: `code /home/krs/Projects/fireManagement`
3. Terminal: `` Ctrl+` ``
4. Enter environment: `nix develop`
5. Install Flutter 3.3.0: `make install-flutter` (or manually)
6. Get dependencies: `make get-deps`
7. Start developing: `flutter run`

All done! You now have a reproducible development environment that works across machines.
