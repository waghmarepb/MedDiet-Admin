#!/bin/bash

# Cloudflare Pages Build Script for Flutter Web

echo "🚀 Starting Flutter Web build..."

# Install Flutter if not present
if ! command -v flutter &> /dev/null; then
    echo "📦 Installing Flutter..."
    git clone https://github.com/flutter/flutter.git -b stable --depth 1 /opt/flutter
    export PATH="$PATH:/opt/flutter/bin"
fi

# Get Flutter version
flutter --version

# Enable web support
flutter config --enable-web

# Get dependencies
echo "📥 Getting dependencies..."
flutter pub get

# Build for web
echo "🔨 Building web app..."
flutter build web --release --no-tree-shake-icons

# Copy _headers and _redirects to build/web
if [ -f "_headers" ]; then
    echo "📋 Copying _headers..."
    cp _headers build/web/_headers
fi

if [ -f "_redirects" ]; then
    echo "📋 Copying _redirects..."
    cp _redirects build/web/_redirects
fi

echo "✅ Build completed successfully!"



