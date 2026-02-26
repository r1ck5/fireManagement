#!/usr/bin/env bash
# Flutter 3.3.0 Setup Script with Nix

set -e

echo "╔════════════════════════════════════════════════════════════╗"
echo "║  Flutter 3.3.0 Fire Management - Nix Setup Script          ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# Check if zsh is available (required for Nix)
if ! command -v zsh &> /dev/null; then
    echo "❌ zsh is not installed. Please install zsh first."
    exit 1
fi

# Check if Nix is available
echo "Checking Nix availability..."
if ! zsh -c "nix --version" &> /dev/null; then
    echo "❌ Nix is not available in zsh. Please ensure Nix is installed."
    exit 1
fi

echo "✅ Nix found: $(zsh -c 'nix --version')"
echo ""

# Create Nix development environment
echo "Setting up Nix development environment..."
echo "Run the following command to enter the dev environment:"
echo ""
echo "  zsh -c 'cd $(pwd) && nix develop'"
echo ""
echo "Or if you have direnv installed and enabled:"
echo "  direnv allow"
echo ""

# Check Flutter installation status
echo "Flutter Setup Status:"
if [ -d "$HOME/.flutter" ]; then
    echo "✅ Flutter SDK found at ~/.flutter"
    $HOME/.flutter/bin/flutter --version 2>/dev/null || echo "⚠️  Could not verify Flutter version"
else
    echo "⚠️  Flutter SDK not found at ~/.flutter"
    echo "    You may need to install Flutter 3.3.0 manually"
fi

echo ""
echo "Next steps:"
echo "1. Enter the dev environment: zsh -c 'cd $(pwd) && nix develop'"
echo "2. Run Flutter commands: flutter pub get, flutter run, etc."
echo "3. For VSCode, ensure Dart extension is installed"
echo ""
