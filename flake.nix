{
  description = "Flutter 3.3.0 Fire Management App - Legacy Development Environment";

  inputs = {
    # Pin to a stable nixpkgs version that supports Flutter 3.3.0
    # 23.11 is a solid LTS release with good Flutter support
    nixpkgs.url = "github:nixos/nixpkgs/23.11";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config = {
            allowUnfree = true;
            allowBroken = false;
          };
        };
      in
      {
        devShells.default = pkgs.mkShell {
          name = "flutter-3.3.0-env";

          buildInputs = with pkgs; [
            # ============================================================
            # Java Development Kit
            # ============================================================
            # JDK 11 is compatible with Flutter 3.3.0 and older Gradle
            jdk11

            # ============================================================
            # Android Development
            # ============================================================
            android-tools
            gradle

            # ============================================================
            # Build Tools
            # ============================================================
            cmake
            ninja
            pkg-config
            gnumake

            # ============================================================
            # Version Control & Utilities
            # ============================================================
            git
            which
            curl
            wget
            unzip
            zip

            # ============================================================
            # Development Tools
            # ============================================================
            vim
            nano

            # ============================================================
            # System Libraries (may be needed for compilation)
            # ============================================================
            llvm
            libclang
            glibc
          ];

          shellHook = ''
            set +e  # Don't exit on error in this hook

            # ============================================================
            # Java Configuration
            # ============================================================
            export JAVA_HOME=${pkgs.jdk11}
            export PATH=$JAVA_HOME/bin:$PATH
            export JAVA_OPTS="-Xmx4096m -XX:MaxPermSize=1024m"

            # ============================================================
            # Android Configuration
            # ============================================================
            export ANDROID_HOME=$HOME/.android
            export ANDROID_SDK_ROOT=$ANDROID_HOME
            export ANDROID_USER_HOME=$ANDROID_HOME
            
            # Set up Android SDK paths
            export PATH=$ANDROID_SDK_ROOT/tools:$PATH
            export PATH=$ANDROID_SDK_ROOT/tools/bin:$PATH
            export PATH=$ANDROID_SDK_ROOT/platform-tools:$PATH
            export PATH=$ANDROID_SDK_ROOT/build-tools/33.0.0:$PATH

            # ============================================================
            # Flutter Configuration
            # ============================================================
            export PUB_CACHE=$PWD/.pub-cache
            export FLUTTER_NO_ANALYTICS=true
            export FLUTTER_SUPPRESS_ANALYTICS=true
            
            # Use system Flutter if available
            if [ -d "$HOME/.flutter" ]; then
              export FLUTTER_ROOT=$HOME/.flutter
              export PATH=$FLUTTER_ROOT/bin:$PATH
              export PATH=$FLUTTER_ROOT/bin/cache/dart-sdk/bin:$PATH
            fi

            # ============================================================
            # Gradle Configuration
            # ============================================================
            export GRADLE_USER_HOME=$PWD/.gradle
            export GRADLE_OPTS="-Xmx2048m -XX:MaxPermSize=512m"

            # ============================================================
            # Build Configuration
            # ============================================================
            export CMAKE_PREFIX_PATH=${pkgs.cmake}:${pkgs.ninja}
            export LD_LIBRARY_PATH=${pkgs.lib.makeLibraryPath [
              pkgs.libclang.lib
              pkgs.llvm.lib
            ]}:$LD_LIBRARY_PATH

            # ============================================================
            # Nix-specific configuration
            # ============================================================
            export NIXPKGS_SYSTEM=${system}

            # ============================================================
            # Display Information Banner
            # ============================================================
            echo ""
            echo "╔════════════════════════════════════════════════════════════╗"
            echo "║  Flutter 3.3.0 Fire Management App - Nix Dev Environment  ║"
            echo "║  System: ${system}                           "
            echo "╚════════════════════════════════════════════════════════════╝"
            echo ""
            
            # Check Java
            echo "📦 Java Configuration:"
            java_version=$(java -version 2>&1 | head -1)
            echo "   $java_version"
            echo ""

            # Check Gradle
            echo "📦 Build Tools:"
            gradle_version=$(gradle --version 2>&1 | head -2 | tail -1)
            echo "   Gradle: $gradle_version"
            echo "   CMake: $(cmake --version 2>&1 | head -1)"
            echo "   Ninja: $(ninja --version 2>&1)"
            echo ""

            # Check Flutter
            echo "📦 Flutter Configuration:"
            if [ -d "$FLUTTER_ROOT" ]; then
              flutter_version=$($FLUTTER_ROOT/bin/flutter --version 2>&1 | head -1)
              echo "   $flutter_version"
              dart_version=$($FLUTTER_ROOT/bin/dart --version 2>&1)
              echo "   Dart: $dart_version"
            else
              echo "   ⚠️  Flutter not found at ~/.flutter"
              echo "   Install Flutter 3.3.0 from: https://flutter.dev/docs/release/archive"
            fi
            echo ""

            # Show important paths
            echo "📂 Important Paths:"
            echo "   JAVA_HOME: $JAVA_HOME"
            echo "   ANDROID_HOME: $ANDROID_HOME"
            echo "   PUB_CACHE: $PUB_CACHE"
            echo "   GRADLE_USER_HOME: $GRADLE_USER_HOME"
            echo ""

            # Check for connected devices
            echo "📱 Checking for connected devices:"
            if command -v adb &> /dev/null; then
              device_count=$(adb devices 2>/dev/null | wc -l)
              if [ "$device_count" -gt 2 ]; then
                echo "   ✅ Connected devices found"
                adb devices 2>/dev/null | grep -v "^$" | grep -v "List" || true
              else
                echo "   ℹ️  No devices detected (run 'adb devices' to check)"
              fi
            else
              echo "   ℹ️  adb not yet configured"
            fi
            echo ""

            # Helpful commands
            echo "📚 Useful Commands:"
            echo "   flutter pub get            - Get dependencies"
            echo "   flutter run                - Run on connected device"
            echo "   flutter build apk          - Build APK"
            echo "   flutter test               - Run tests"
            echo "   dart analyze               - Analyze code"
            echo "   dart format lib/           - Format code"
            echo ""
            echo "💡 Exit this environment with: exit"
            echo ""
          '';
        };
      }
    );
}
