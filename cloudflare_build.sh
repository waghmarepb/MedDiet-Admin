#!/bin/bash
set -e

echo "🚀 Starting Cloudflare Pages Flutter Build..."

# Install Flutter in current directory (writable)
FLUTTER_DIR="$PWD/flutter_sdk"
export PATH="$FLUTTER_DIR/bin:$PATH"
export PATH="$FLUTTER_DIR/bin/cache/dart-sdk/bin:$PATH"

# Clone Flutter if not exists
if [ ! -d "$FLUTTER_DIR" ]; then
    echo "📦 Downloading Flutter SDK..."
    git clone https://github.com/flutter/flutter.git -b stable --depth 1 "$FLUTTER_DIR"
fi

# Configure Flutter
echo "⚙️ Configuring Flutter..."
$FLUTTER_DIR/bin/flutter config --enable-web --no-analytics

# Precache web
echo "📦 Precaching web..."
$FLUTTER_DIR/bin/flutter precache --web

# Show Flutter version
echo "📋 Flutter version:"
$FLUTTER_DIR/bin/flutter --version

# Get dependencies
echo "📥 Getting dependencies..."
$FLUTTER_DIR/bin/flutter pub get

# Build web
echo "🔨 Building web app..."
$FLUTTER_DIR/bin/flutter build web --release

# Copy config files
echo "📋 Copying config files..."
[ -f "_headers" ] && cp _headers build/web/_headers && echo "✅ Copied _headers"
[ -f "_redirects" ] && cp _redirects build/web/_redirects && echo "✅ Copied _redirects"

echo "✅ Build complete!"
echo "📦 Output: build/web"
ls -la build/web/ | head -20

