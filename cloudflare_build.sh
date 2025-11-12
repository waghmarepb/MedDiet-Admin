#!/bin/bash
set -e

echo "🚀 Starting Cloudflare Pages Flutter Build..."

# Save current directory (project root)
PROJECT_DIR="$PWD"

# Install Flutter in current directory (writable)
FLUTTER_DIR="$PROJECT_DIR/flutter_sdk"

# Clone Flutter if not exists
if [ ! -d "$FLUTTER_DIR" ]; then
    echo "📦 Downloading Flutter SDK..."
    git clone https://github.com/flutter/flutter.git -b stable --depth 1 "$FLUTTER_DIR"
fi

# Set Flutter path
export PATH="$FLUTTER_DIR/bin:$PATH"
export PATH="$FLUTTER_DIR/bin/cache/dart-sdk/bin:$PATH"

# Configure Flutter
echo "⚙️ Configuring Flutter..."
flutter config --enable-web --no-analytics

# Precache web
echo "📦 Precaching web..."
flutter precache --web

# Show Flutter version
echo "📋 Flutter version:"
flutter --version

# Ensure we're in project directory
cd "$PROJECT_DIR"

# Get dependencies
echo "📥 Getting dependencies..."
flutter pub get

# Build web
echo "🔨 Building web app..."
flutter build web --release

# Copy config files
echo "📋 Copying config files..."
[ -f "_headers" ] && cp _headers build/web/_headers && echo "✅ Copied _headers"
[ -f "_redirects" ] && cp _redirects build/web/_redirects && echo "✅ Copied _redirects"

echo "✅ Build complete!"
echo "📦 Output: build/web"
ls -la build/web/ | head -20

