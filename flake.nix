{
  description = "Flutter 3.3.0 Fire Management App - Nix Flake with Android Dev Environment & Emulator";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
    flake-utils.url = "github:numtide/flake-utils";
    android-nixpkgs-src = {
      url = "github:tadfisher/android-nixpkgs/main";
      flake = false;
    };
    flutter-src = {
      url = "https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.3.0-stable.tar.xz";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, flake-utils, android-nixpkgs-src, flutter-src }:
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

        # Clean Flutter archive by removing .git directory
        flutterArchiveClean = pkgs.runCommand "flutter-3.3.0-clean.tar.xz" { 
          buildInputs = [ pkgs.xz ];
        } ''
          mkdir -p work
          cd work
          xz -d < ${flutter-src} | tar -x
          
          # Remove all .git* files and directories
          find . -name ".git" -type d -exec rm -rf {} + 2>/dev/null || true
          find . -name ".git*" -type f -delete 2>/dev/null || true
          find . -name ".gitignore" -delete 2>/dev/null || true
          find . -name ".gitattributes" -delete 2>/dev/null || true
          
          # Repack the archive
          tar -c . | xz -9 > $out
        '';
        
        # Flutter 3.3.0 from cleaned archive
        flutter330 = pkgs.stdenv.mkDerivation rec {
          pname = "flutter";
          version = "3.3.0";
          src = flutterArchiveClean;
          
          unpackPhase = ''
            tar -xf $src --strip-components=1
          '';
          
          dontBuild = true;
          dontConfigure = true;
          
          installPhase = ''
            # Make all scripts executable
            find . -type f -name "*.sh" -exec chmod +x {} \; 2>/dev/null || true
            [ -f bin/flutter ] && chmod +x bin/flutter || true
            [ -f bin/dart ] && chmod +x bin/dart || true
            
            # Ensure bin directory exists
            mkdir -p bin
          '';
        };
        
        patchedFlutter = flutter330;

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
            wrappedEmulator
            androidEnv
            glibc
            zlib
            ncurses5
            stdenv.cc.cc.lib
          ];

          shellHook = ''
            echo "Setting up Flutter 3.3.0 + Android dev environment..."
            
            # Setup Android environment
            if [ -d "$PWD/.android/sdk" ]; then
              export ANDROID_HOME="$PWD/.android/sdk"
              export ANDROID_SDK_ROOT="$ANDROID_HOME"
            else
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
            fi

            export JAVA_HOME="${pkgs.jdk17}"
            export ANDROID_EMULATOR_HOME="$PWD/.android"
            export FLUTTER_ANDROID_HOME="$ANDROID_HOME"
            
            echo "✅ Flutter 3.3.0 + Android dev environment ready (fast path)"
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

            # Setup Android environment
            if [ -d "$PWD/.android/sdk" ]; then
              export ANDROID_HOME="$PWD/.android/sdk"
              export ANDROID_SDK_ROOT="$ANDROID_HOME"
            else
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
