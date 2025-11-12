#!/bin/bash
set -e

echo "🚀 Starting Flutter Web build for Cloudflare Pages..."

# Save current directory (project root)
PROJECT_DIR="$PWD"

# Set Flutter version
FLUTTER_VERSION="stable"
FLUTTER_DIR="$PROJECT_DIR/flutter_sdk"

# Install Flutter
if [ ! -d "$FLUTTER_DIR" ]; then
    echo "📦 Installing Flutter..."
    git clone https://github.com/flutter/flutter.git -b ${FLUTTER_VERSION} --depth 1 "$FLUTTER_DIR"
fi

# Set Flutter path
export PATH="$FLUTTER_DIR/bin:$PATH"
export PATH="$FLUTTER_DIR/bin/cache/dart-sdk/bin:$PATH"

# Configure Flutter
echo "⚙️ Configuring Flutter..."
flutter config --enable-web --no-analytics

# Precache web dependencies
echo "📦 Precaching Flutter web..."
flutter precache --web

# Get Flutter version
echo "📋 Flutter version:"
flutter --version

# Make sure we're in project directory
cd "$PROJECT_DIR"

# Get dependencies
echo "📥 Getting Flutter dependencies..."
flutter pub get

# Build for web
echo "🔨 Building Flutter web app..."
flutter build web --release

# Copy configuration files
echo "📋 Copying configuration files..."
if [ -f "_headers" ]; then
    cp _headers build/web/_headers
    echo "✅ Copied _headers"
fi

if [ -f "_redirects" ]; then
    cp _redirects build/web/_redirects
    echo "✅ Copied _redirects"
fi

echo "✅ Build completed successfully!"
echo "📦 Output directory: build/web"

