#!/bin/bash
set -e

echo "🔨 Building Flutter Web App..."

# Set up Flutter path
FLUTTER_HOME="$PWD/flutter_sdk"
export PATH="$FLUTTER_HOME/bin:$PATH"
export PATH="$FLUTTER_HOME/bin/cache/dart-sdk/bin:$PATH"

# Get dependencies
echo "📥 Getting dependencies..."
flutter pub get

# Build
echo "🏗️ Building web app..."
flutter build web --release

# Copy config files
echo "📋 Copying configuration files..."
if [ -f "_headers" ]; then
    cp _headers build/web/_headers
    echo "✅ Copied _headers"
fi

if [ -f "_redirects" ]; then
    cp _redirects build/web/_redirects
    echo "✅ Copied _redirects"
fi

echo "✅ Build complete!"
ls -la build/web/



