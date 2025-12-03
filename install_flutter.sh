#!/bin/bash
set -e

echo "🚀 Installing Flutter for Cloudflare Pages..."

# Set up Flutter in a writable directory
FLUTTER_HOME="$PWD/flutter_sdk"
export PATH="$FLUTTER_HOME/bin:$PATH"
export PATH="$FLUTTER_HOME/bin/cache/dart-sdk/bin:$PATH"

# Clone Flutter
if [ ! -d "$FLUTTER_HOME" ]; then
    echo "📦 Cloning Flutter SDK..."
    git clone https://github.com/flutter/flutter.git -b stable --depth 1 "$FLUTTER_HOME"
else
    echo "✅ Flutter SDK already exists"
fi

# Configure Flutter
echo "⚙️ Configuring Flutter..."
flutter config --enable-web --no-analytics

# Precache web
echo "📦 Precaching web dependencies..."
flutter precache --web

echo "✅ Flutter installation complete!"
flutter --version



