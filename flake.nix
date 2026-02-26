{
  description = "Flutter 3.3.0 Fire Management App - Nix Flake with Android Dev Environment & Emulator";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
    flake-utils.url = "github:numtide/flake-utils";
    android-nixpkgs-src = {
      url = "github:tadfisher/android-nixpkgs/main";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, flake-utils, android-nixpkgs-src }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config = {
            allowUnfree = true;
            android_sdk.accept_license = true;
          };
        };

        # Patch android-nixpkgs to fix compatibility issues
        patchedAndroidNixpkgsSrc = pkgs.runCommand "android-nixpkgs-patched" {} ''
          cp -r ${android-nixpkgs-src} $out
          chmod -R +w $out
          substituteInPlace $out/default.nix \
            --replace "lib.meta.availableOn hostPlatform pkg" \
                      "lib.meta.availableOn pkgs.stdenv.hostPlatform pkg"
        '';

        android-nixpkgs = import patchedAndroidNixpkgsSrc {
          inherit pkgs system;
        };

        # Android environment with required SDK components for Flutter 3.3.0
        androidEnv = android-nixpkgs.sdk (sdkPkgs: with sdkPkgs; [
          cmdline-tools-latest
          build-tools-34-0-0
          platform-tools
          platforms-android-34
          emulator
          ndk-25-1-8937393  # NDK version compatible with Flutter 3.3.0
          system-images-android-34-google-apis-playstore-x86-64
        ]) // {
          buildInputs = (androidEnv.buildInputs or []) ++ (with pkgs; [
            xcb-util-cursor
            xorg.libXcursor
            xorg.libX11
            xorg.libxcb
            qt6.qtbase
            qt6.qtsvg
          ]);
        };

        # Emulator wrapper script
        wrappedEmulator = pkgs.writeShellScriptBin "run-emulator" ''
          #!/usr/bin/env bash
          set -e
          
          echo "Launching Android emulator..."
          echo ""

          # Setup display
          echo "🔐 Configuring display..."
          if [ -z "$DISPLAY" ]; then
            echo "ERROR: DISPLAY is not set. Please run this in a graphical environment."
            exit 1
          fi
          
          echo "   DISPLAY: $DISPLAY"
          
          # Grant X11 access
          XHOST="${pkgs.xorg.xhost}/bin/xhost"
          if [ -x "$XHOST" ]; then
            "$XHOST" +local: > /dev/null 2>&1 || true
            echo "   ✅ X11 access configured"
          fi

          # Setup environment
          export ANDROID_HOME="$PWD/.android/sdk"
          export ANDROID_SDK_ROOT="$ANDROID_HOME"
          export PATH="$ANDROID_HOME/bin:$ANDROID_HOME/platform-tools:$PATH"

          # Setup FHS library paths
          if [ -n "$FHS_LIB" ]; then
            export LD_LIBRARY_PATH="$FHS_LIB/usr/lib:$LD_LIBRARY_PATH"
          fi

          # Qt configuration
          export QT_QPA_PLATFORM=xcb
          export QT_QPA_PLATFORM_PLUGIN_PATH="${pkgs.qt6.qtbase}/lib/qt-6/plugins"
          export QT_PLUGIN_PATH="${pkgs.qt6.qtbase}/lib/qt-6/plugins"
          export QTWEBENGINE_DISABLE_SANDBOX=1

          # Detect graphics capability and choose rendering mode
          echo ""
          echo "📊 Graphics configuration..."
          
          # Try to detect if we can do hardware rendering
          # Most NixOS systems need software rendering due to Vulkan driver issues
          if [ -f "/run/opengl-driver/lib/libvulkan.so" ] || [ -f "/run/opengl-driver/lib/libvulkan.so.1" ]; then
            echo "   ℹ️  NVIDIA driver detected, attempting hardware rendering"
            GPU_MODE="-gpu host"
          elif lspci 2>/dev/null | grep -q "VGA\|3D"; then
            # Check if hardware is present (but still might not work due to Vulkan issues)
            echo "   ℹ️  Graphics card detected, attempting hardware rendering"
            GPU_MODE="-gpu host"
          else
            echo "   ℹ️  Using software rendering (slower but more compatible)"
            GPU_MODE="-gpu swiftshader_indirect"
          fi

          echo ""
          echo "🚀 Starting emulator with $GPU_MODE..."
          echo ""

          # Start the emulator
          exec emulator -avd android_emulator \
            $GPU_MODE \
            -no-snapshot \
            -no-snapshot-load \
            -no-snapshot-save \
            -port 5554 \
            -grpc 8554 \
            -no-metrics 2>&1
        '';

        # Flutter 3.3.0 with adjusted cmake/ninja paths
        patchedFlutter = pkgs.flutter.overrideAttrs (oldAttrs: {
          patchPhase = ''
            runHook prePatch
            substituteInPlace $FLUTTER_ROOT/packages/flutter_tools/gradle/src/main/kotlin/FlutterTask.kt \
              --replace 'val cmakeExecutable = project.file(cmakePath).absolutePath' 'val cmakeExecutable = "cmake"' \
              --replace 'val ninjaExecutable = project.file(ninjaPath).absolutePath' 'val ninjaExecutable = "ninja"'
            find $FLUTTER_ROOT -name "*.gradle" -o -name "*.gradle.kts" | xargs -I {} \
              sed -i 's|cmake/[^/]*/bin/cmake|cmake|g' {} 2>/dev/null || true
            runHook postPatch
          '';
        });

        # Build version constraints for Flutter 3.3.0
        minSdkVersion = "21";
        kotlinVersion = "1.7.21";
        agpVersion = "7.3.1";
        ndkVersion = "25.1.8937393";

      in
      {
        devShells.default = (pkgs.buildFHSEnv {
          name = "FHS flutter-3.3.0-android-env";
          targetPkgs = pkgs: with pkgs; [
            bashInteractive
            git
            cmake
            ninja
            python3
            jdk17
            gradle
            patchedFlutter
            wrappedEmulator
            androidEnv
            patchelf
            glibc
            zlib
            ncurses5
            stdenv.cc.cc.lib
            libsForQt5.qt5.qtbase
            libsForQt5.qt5.qtsvg
            libsForQt5.qt5.qtwayland
            qt6.qtbase
            qt6.qtsvg
            qt6.qtwayland
            xorg.libX11
            xorg.libXext
            xorg.libXfixes
            xorg.libXi
            xorg.libXrandr
            xorg.libXrender
            xorg.libxcb
            xorg.xcbutil
            xorg.xcbutilwm
            xorg.xcbutilimage
            xorg.xcbutilkeysyms
            xorg.xcbutilrenderutil
            libxkbcommon
            mesa
            libdrm
            vulkan-loader
            fontconfig
            freetype
            libglvnd
            dbus
            libpulseaudio
            udev
            libinput
            at-spi2-core
            gtk3
            gdk-pixbuf
            cairo
            pango
            xcb-util-cursor
            xorg.libXcursor
            xorg.setxkbmap
            xorg.xauth
            xorg.xhost
          ];

          multiPkgs = pkgs: with pkgs; [
            zlib
            ncurses5
            mesa
          ];

          profile = ''
            echo "Setting up Flutter 3.3.0 + Android dev environment..."
            
            export PATH="$FHS_LIB/usr/bin:$PATH"
            
            export NIX_LD_LIBRARY_PATH="${pkgs.lib.makeLibraryPath [
              pkgs.glibc
              pkgs.zlib
              pkgs.ncurses5
              pkgs.stdenv.cc.cc.lib
              pkgs.libsForQt5.qt5.qtbase
              pkgs.libsForQt5.qt5.qtsvg
              pkgs.qt6.qtbase
              pkgs.qt6.qtsvg
              pkgs.xorg.libX11
              pkgs.xorg.libXext
              pkgs.xorg.libXfixes
              pkgs.xorg.libXi
              pkgs.xorg.libXrandr
              pkgs.xorg.libXrender
              pkgs.xorg.libxcb
              pkgs.mesa
              pkgs.libdrm
              pkgs.vulkan-loader
              pkgs.libglvnd
              pkgs.fontconfig
              pkgs.freetype
              pkgs.gtk3
              pkgs.xcb-util-cursor
              pkgs.xorg.libXcursor
            ]}"

            export LD_LIBRARY_PATH="$NIX_LD_LIBRARY_PATH:$LD_LIBRARY_PATH"

            # Fast path for subsequent runs
            if [ -f "$PWD/.flutter_env_ready" ] && [ -d "$PWD/.android/sdk" ]; then
              export ANDROID_HOME="$PWD/.android/sdk"
              export ANDROID_SDK_ROOT="$ANDROID_HOME"
              export JAVA_HOME="${pkgs.jdk17}"
              export PATH="${pkgs.cmake}/bin:${pkgs.ninja}/bin:$PATH"
              export LD_LIBRARY_PATH="$FHS_LIB/usr/lib:$LD_LIBRARY_PATH"
              export ANDROID_EMULATOR_HOME="$PWD/.android"

              echo "✅ Flutter environment ready (fast path)"
              echo ""
              echo "👉 Quick commands:"
              echo "   flutter run              - Run on connected device"
              echo "   run-emulator             - Launch Android emulator"
              echo "   flutter build apk        - Build APK"
            else
              # Full setup on first run
              echo "Performing full environment setup (first run)..."
              echo ""

              "${androidEnv}/share/android-sdk/platform-tools/adb" kill-server &> /dev/null || true

              mkdir -p "$PWD/.android/sdk"
              export ANDROID_HOME="$PWD/.android/sdk"
              export ANDROID_SDK_ROOT="$ANDROID_HOME"
              export JAVA_HOME="${pkgs.jdk17}"

              gradle --version
              echo "🔧 Using Java:"
              "$JAVA_HOME/bin/java" -version
              echo ""

              mkdir -p "$ANDROID_HOME/licenses" "$ANDROID_HOME/avd" "$ANDROID_HOME/bin"
              cp -LR ${androidEnv}/share/android-sdk/* "$ANDROID_HOME/" || true

              for bin in adb avdmanager emulator sdkmanager; do
                cp -LR ${androidEnv}/bin/$bin "$ANDROID_HOME/bin/" || true
              done
              rm -rf "$ANDROID_HOME/cmake"

              # Create cmake symlinks
              mkdir -p "$ANDROID_HOME/cmake/3.22.1/bin"
              ln -sf "${pkgs.cmake}/bin/cmake" "$ANDROID_HOME/cmake/3.22.1/bin/cmake"
              ln -sf "${pkgs.ninja}/bin/ninja" "$ANDROID_HOME/cmake/3.22.1/bin/ninja"

              chmod -R u+w "$ANDROID_HOME"
              find "$ANDROID_HOME/bin" "$ANDROID_HOME/platform-tools" \
                   "$ANDROID_HOME/emulator" "$ANDROID_HOME/cmdline-tools/latest/bin" \
                   "$ANDROID_HOME/build-tools" -type f -exec chmod +x {} \; 2>/dev/null || true

              # Accept licenses
              for license in android-sdk-license android-sdk-preview-license googletv-license; do
                touch "$ANDROID_HOME/licenses/$license"
              done
              yes | flutter doctor --android-licenses || true

              flutter config --android-sdk "$ANDROID_HOME"

              # Initialize project if needed
              if [ ! -f pubspec.yaml ]; then
                flutter create .
                echo ".android/sdk" >> .gitignore
              fi

              if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
                git init
                git add .
                git commit -m "Initial Flake setup"
              fi

              mkdir -p android/app/src/main/{kotlin,java} android/app/src/debug/{kotlin,java}
              mkdir -p android/app/src/profile/{kotlin,java} android/app/src/release/{kotlin,java}

              # Configure gradle
              mkdir -p android
              touch android/gradle.properties
              sed -i '/^android\.cmake\.path=/d' android/gradle.properties
              sed -i '/^android\.ninja\.path=/d' android/gradle.properties
              echo "android.cmake.path=${pkgs.cmake}/bin" >> android/gradle.properties
              echo "android.ninja.path=${pkgs.ninja}/bin" >> android/gradle.properties

              # Create AVD
              if ! avdmanager list avd 2>/dev/null | grep -q 'android_emulator'; then
                echo "Creating Android emulator..."
                yes | avdmanager create avd \
                  --name "android_emulator" \
                  --package "system-images;android-34;google_apis_playstore;x86_64" \
                  --device "pixel" \
                  --abi "x86_64" \
                  --tag "google_apis_playstore" \
                  --force
              fi

              export PATH="${pkgs.cmake}/bin:${pkgs.ninja}/bin:$PATH"
              flutter doctor --quiet
              echo "✅ Flutter + Android dev shell ready"
              touch "$PWD/.flutter_env_ready"

              echo ""
              echo "📚 Common Commands:"
              echo "   flutter pub get          - Install dependencies"
              echo "   flutter run              - Run on connected device"
              echo "   run-emulator             - Launch Android emulator"
              echo "   flutter build apk        - Build APK release"
              echo "   flutter test             - Run tests"
              echo "   dart analyze             - Analyze code"
            fi
          '';
          runScript = "bash";
        }).env;
      }
    );
}
