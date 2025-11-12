#!/bin/bash

echo "🚀 Starting Flutter Web build for Cloudflare Pages..."

# Set Flutter version
FLUTTER_VERSION="3.24.5"
FLUTTER_CHANNEL="stable"

# Install Flutter
if [ ! -d "/opt/flutter" ]; then
    echo "📦 Installing Flutter ${FLUTTER_VERSION}..."
    cd /opt
    git clone https://github.com/flutter/flutter.git -b ${FLUTTER_CHANNEL} --depth 1
    export PATH="$PATH:/opt/flutter/bin"
else
    echo "✅ Flutter already installed"
    export PATH="$PATH:/opt/flutter/bin"
fi

# Configure Flutter
echo "⚙️ Configuring Flutter..."
flutter config --enable-web --no-analytics

# Get Flutter version
echo "📋 Flutter version:"
flutter --version

# Return to project directory
cd $CF_PAGES_BUILD_DIR

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

