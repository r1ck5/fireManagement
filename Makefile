.PHONY: help env get-deps generate build-debug build-release test format analyze clean install-flutter

# Default target
help:
	@echo "Flutter 3.3.0 Fire Management App - Nix Development"
	@echo "===================================================="
	@echo ""
	@echo "Setup Commands:"
	@echo "  make install-flutter    - Download and install Flutter 3.3.0 to ~/.flutter"
	@echo "  make env                - Enter Nix development environment (zsh required)"
	@echo ""
	@echo "Development Commands (run inside 'nix develop'):"
	@echo "  make get-deps           - flutter pub get (get dependencies)"
	@echo "  make generate           - Generate code (JSON serialization, etc.)"
	@echo "  make watch-generate     - Watch for changes and auto-generate code"
	@echo "  make build-debug        - Build debug APK"
	@echo "  make build-release      - Build release APK"
	@echo "  make build-appbundle    - Build App Bundle for Play Store"
	@echo "  make run                - Run app on connected device"
	@echo "  make test               - Run tests"
	@echo "  make format             - Format Dart code"
	@echo "  make analyze            - Analyze code for issues"
	@echo "  make clean              - Clean build artifacts"
	@echo ""
	@echo "Examples:"
	@echo "  make install-flutter && make env"
	@echo "  make get-deps && make generate && make run"
	@echo ""

# Nix environment
env:
	@echo "Entering Nix development environment..."
	@nix develop

# Installation
install-flutter:
	@echo "Installing Flutter 3.3.0..."
	@mkdir -p ~/.flutter
	@cd ~/.flutter && \
	if [ ! -f flutter/bin/flutter ]; then \
		echo "Downloading Flutter 3.3.0..."; \
		wget https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter-linux-3.3.0-stable.tar.gz 2>/dev/null || curl -O https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter-linux-3.3.0-stable.tar.gz; \
		tar xzf flutter-linux-3.3.0-stable.tar.gz; \
		rm flutter-linux-3.3.0-stable.tar.gz; \
	fi
	@~/.flutter/bin/flutter --version

# Dependency management
get-deps:
	flutter pub get

generate:
	flutter pub run build_runner build --delete-conflicting-outputs

watch-generate:
	flutter pub run build_runner watch

# Build commands
build-debug:
	flutter build apk

build-release:
	flutter build apk --release

build-appbundle:
	flutter build appbundle --release

# Runtime
run:
	flutter run

devices:
	flutter devices

# Testing and code quality
test:
	flutter test

analyze:
	dart analyze

format:
	dart format lib/

# Cleanup
clean:
	flutter clean
	rm -rf build/
	rm -rf .dart_tool/
	rm -rf pubspec.lock

# One-time setup
setup: install-flutter get-deps generate
	@echo "✅ Setup complete! You can now run 'make run'"
