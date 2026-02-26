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
           
           # Check if hardware GPU is requested via command line argument
           if [ "$1" = "--gpu" ] || [ "$1" = "-gpu" ]; then
             echo "   ℹ️  Hardware GPU requested via command line"
             GPU_MODE="-gpu host"
           else
             echo "   ℹ️  Using software rendering (more reliable on NixOS)"
             echo "   💡 Tip: Run 'run-emulator --gpu' to attempt hardware rendering"
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

        # Flutter 3.3.0 as a proper Git clone (required by Flutter tools)
        setupFlutter = pkgs.writeShellScriptBin "setup-flutter" ''
          #!/usr/bin/env bash
          set -e
          
          FLUTTER_HOME="$PWD/.flutter"
          
          if [ ! -d "$FLUTTER_HOME" ]; then
            echo "🚀 Cloning Flutter 3.3.0 repository..."
            git clone --depth 1 --branch 3.3.0 https://github.com/flutter/flutter.git "$FLUTTER_HOME"
          else
            echo "✅ Flutter already cloned at $FLUTTER_HOME"
          fi
          
          # Verify it's a proper git clone
          if [ ! -d "$FLUTTER_HOME/.git" ]; then
            echo "❌ ERROR: Flutter clone is missing .git directory"
            exit 1
          fi
          
          export PATH="$FLUTTER_HOME/bin:$PATH"
          export FLUTTER_ROOT="$FLUTTER_HOME"
          echo "✅ Flutter 3.3.0 path configured"
        '';
        
        patchedFlutter = pkgs.flutter;

        # Build version constraints for Flutter 3.3.0
        minSdkVersion = "21";
        kotlinVersion = "1.7.21";
        agpVersion = "7.3.1";
        ndkVersion = "25.1.8937393";

      in
      {
        # Fast dev shell for daily development (no FHS overhead)
        devShells.default = pkgs.mkShell {
          name = "flutter-3.3.0-dev";
          buildInputs = with pkgs; [
            bashInteractive
            git
            cmake
            ninja
            python3
            jdk17
            gradle
            patchedFlutter
            setupFlutter
            wrappedEmulator
            androidEnv
            glibc
            zlib
            ncurses5
            stdenv.cc.cc.lib
          ];

          shellHook = ''
            echo "Setting up Flutter 3.3.0 + Android dev environment..."
            
            # Setup Flutter as proper Git clone (only once)
            FLUTTER_HOME="$PWD/.flutter"
            FLUTTER_INIT_FILE="$FLUTTER_HOME/.init_done"
            
            # Export PATH early so flutter commands work
            export PATH="$FLUTTER_HOME/bin:$PATH"
            export FLUTTER_ROOT="$FLUTTER_HOME"
            
            if [ ! -f "$FLUTTER_INIT_FILE" ]; then
              if [ ! -d "$FLUTTER_HOME/.git" ]; then
                echo "🚀 Cloning Flutter 3.3.0 repository..."
                git clone --depth 1 --branch 3.3.0 https://github.com/flutter/flutter.git "$FLUTTER_HOME" 2>&1 | grep -v "^Cloning into" || true
                echo "✅ Flutter 3.3.0 cloned successfully"
              fi
              
              # Configure git remotes and channels for Flutter (only once)
              cd "$FLUTTER_HOME"
              git remote set-url origin https://github.com/flutter/flutter.git 2>/dev/null || true
              git config user.email "flutter@local" 2>/dev/null || true
              git config user.name "Flutter Dev" 2>/dev/null || true
              
              # Create .channel file to indicate stable channel
              mkdir -p "$FLUTTER_HOME/bin/cache"
              echo "stable" > "$FLUTTER_HOME/bin/cache/.channel" 2>/dev/null || true
              
              cd - > /dev/null
              
              # Download Flutter engine binaries and configure (only once)
              echo "⚙️  Downloading Flutter engine binaries and configuring..."
              flutter --version 2>&1 | head -3
              
              echo "⚙️  Disabling analytics..."
              flutter config --no-analytics
              
              echo "⚙️  Accepting Android licenses..."
              yes | flutter doctor --android-licenses 2>/dev/null || true
              
              # Mark initialization as done
              touch "$FLUTTER_INIT_FILE"
              echo "✅ Flutter initialization complete"
            else
              echo "✅ Flutter 3.3.0 already configured"
            fi
            
            # Setup Android environment (fast path - only check, don't recopy every time)
            if [ ! -d "$PWD/.android/sdk" ]; then
              echo "📦 Setting up Android SDK..."
              mkdir -p "$PWD/.android/sdk"
              export ANDROID_HOME="$PWD/.android/sdk"
              export ANDROID_SDK_ROOT="$ANDROID_HOME"
              cp -LR ${androidEnv}/share/android-sdk/* "$ANDROID_HOME/" 2>/dev/null || true
              
              for bin in adb avdmanager emulator sdkmanager; do
                cp -LR ${androidEnv}/bin/$bin "$ANDROID_HOME/bin/" 2>/dev/null || true
              done
              
              mkdir -p "$ANDROID_HOME/licenses"
              for license in android-sdk-license android-sdk-preview-license googletv-license; do
                touch "$ANDROID_HOME/licenses/$license"
              done
              
              chmod -R u+w "$ANDROID_HOME" 2>/dev/null || true
              echo "✅ Android SDK configured"
            else
              export ANDROID_HOME="$PWD/.android/sdk"
              export ANDROID_SDK_ROOT="$ANDROID_HOME"
            fi

            export JAVA_HOME="${pkgs.jdk17}"
            export ANDROID_EMULATOR_HOME="$PWD/.android"
            export FLUTTER_ANDROID_HOME="$ANDROID_HOME"
            
            echo "✅ Flutter 3.3.0 + Android dev environment ready"
          '';
        };

        # FHS shell for building (slower but more compatible)
        devShells.fhs = (pkgs.buildFHSEnv {
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
            echo "Setting up Flutter 3.3.0 + Android dev environment (FHS)..."
            
            export PATH="$FHS_LIB/usr/bin:$PATH"
            
            # Setup Flutter as proper Git clone (only once)
            FLUTTER_HOME="$PWD/.flutter"
            FLUTTER_INIT_FILE="$FLUTTER_HOME/.init_done"
            
            # Export PATH early so flutter commands work
            export PATH="$FLUTTER_HOME/bin:$PATH"
            export FLUTTER_ROOT="$FLUTTER_HOME"
            
            if [ ! -f "$FLUTTER_INIT_FILE" ]; then
              if [ ! -d "$FLUTTER_HOME/.git" ]; then
                echo "🚀 Cloning Flutter 3.3.0 repository..."
                git clone --depth 1 --branch 3.3.0 https://github.com/flutter/flutter.git "$FLUTTER_HOME" 2>&1 | grep -v "^Cloning into" || true
                echo "✅ Flutter 3.3.0 cloned successfully"
              fi
              
              # Configure git remotes and channels for Flutter (only once)
              cd "$FLUTTER_HOME"
              git remote set-url origin https://github.com/flutter/flutter.git 2>/dev/null || true
              git config user.email "flutter@local" 2>/dev/null || true
              git config user.name "Flutter Dev" 2>/dev/null || true
              
              # Create .channel file to indicate stable channel
              mkdir -p "$FLUTTER_HOME/bin/cache"
              echo "stable" > "$FLUTTER_HOME/bin/cache/.channel" 2>/dev/null || true
              
              cd - > /dev/null
              
              # Download Flutter engine binaries and configure (only once)
              echo "⚙️  Downloading Flutter engine binaries and configuring..."
              flutter --version 2>&1 | head -3
              
              echo "⚙️  Disabling analytics..."
              flutter config --no-analytics
              
              echo "⚙️  Accepting Android licenses..."
              yes | flutter doctor --android-licenses 2>/dev/null || true
              
              # Mark initialization as done
              touch "$FLUTTER_INIT_FILE"
              echo "✅ Flutter initialization complete"
            else
              echo "✅ Flutter 3.3.0 already configured"
            fi
            
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

            # Setup Android environment (fast path - only check, don't recopy every time)
            if [ ! -d "$PWD/.android/sdk" ]; then
              echo "📦 Setting up Android SDK..."
              mkdir -p "$PWD/.android/sdk"
              export ANDROID_HOME="$PWD/.android/sdk"
              export ANDROID_SDK_ROOT="$ANDROID_HOME"
              cp -LR ${androidEnv}/share/android-sdk/* "$ANDROID_HOME/" 2>/dev/null || true
              
              for bin in adb avdmanager emulator sdkmanager; do
                cp -LR ${androidEnv}/bin/$bin "$ANDROID_HOME/bin/" 2>/dev/null || true
              done
              
              mkdir -p "$ANDROID_HOME/licenses"
              for license in android-sdk-license android-sdk-preview-license googletv-license; do
                touch "$ANDROID_HOME/licenses/$license"
              done
              
              chmod -R u+w "$ANDROID_HOME" 2>/dev/null || true
              echo "✅ Android SDK configured"
            else
              export ANDROID_HOME="$PWD/.android/sdk"
              export ANDROID_SDK_ROOT="$ANDROID_HOME"
            fi

            export JAVA_HOME="${pkgs.jdk17}"
            export PATH="${pkgs.cmake}/bin:${pkgs.ninja}/bin:$PATH"
            export ANDROID_EMULATOR_HOME="$PWD/.android"
            export FLUTTER_ANDROID_HOME="$ANDROID_HOME"
            export LD_LIBRARY_PATH="$FHS_LIB/usr/lib:$LD_LIBRARY_PATH"
            
            echo "✅ Flutter 3.3.0 + Android dev environment ready (FHS)"
          '';
          runScript = "bash";
        }).env;
      }
    );
}
