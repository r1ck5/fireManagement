#!/usr/bin/env zsh
# Flutter 3.3.0 Quick Start with Nix
# Run this script to check prerequisites and enter the dev environment

set -e

echo "🚀 Flutter 3.3.0 Nix Environment - Quick Start"
echo "=============================================="
echo ""

# Check Nix
echo "✓ Checking Nix..."
if ! command -v nix &> /dev/null; then
    echo "✗ Nix not found. Please ensure Nix is installed in zsh."
    exit 1
fi
echo "  Nix version: $(nix --version)"
echo ""

# Check Flutter
echo "✓ Checking Flutter 3.3.0..."
if [ ! -d "$HOME/.flutter" ]; then
    echo "✗ Flutter not found at ~/.flutter"
    echo ""
    echo "Please download Flutter 3.3.0:"
    echo ""
    echo "  mkdir -p ~/.flutter"
    echo "  cd ~/.flutter"
    echo "  wget https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter-linux-3.3.0-stable.tar.gz"
    echo "  tar xzf flutter-linux-3.3.0-stable.tar.gz"
    echo "  rm flutter-linux-3.3.0-stable.tar.gz"
    echo ""
    exit 1
fi

flutter_version=$($HOME/.flutter/bin/flutter --version 2>&1 | head -1)
echo "  $flutter_version"
echo ""

# Check Java
echo "✓ Checking Java..."
if command -v java &> /dev/null; then
    java_version=$(java -version 2>&1 | head -1)
    echo "  System Java: $java_version"
else
    echo "  (Java will be provided by Nix environment)"
fi
echo ""

# Offer to enter environment
echo "✅ All prerequisites met!"
echo ""
echo "Next: Enter the development environment"
echo ""
echo "Run: nix develop"
echo ""
echo "Or use this one-liner:"
echo "  nix develop --command zsh"
echo ""
