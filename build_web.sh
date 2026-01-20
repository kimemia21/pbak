#!/bin/bash

# Flutter Web Release Build Script
# Usage: ./build_web.sh

PROXY_URL="https://members.pbak.co.ke:5020/api/v1/places"

echo "🚀 Building Flutter Web (Release) with proxy..."
echo "----------------------------------"
echo "----------------------------------"

echo "----------------------------------"

echo "----------------------------------"

echo "----------------------------------"

echo "----------------------------------"

echo " please rember to enable tje next step validation in register screen"

echo "----------------------------------"

echo "----------------------------------"

echo "----------------------------------"

echo "----------------------------------"

echo "📍 Proxy URL: $PROXY_URL"
echo ""




flutter build web --release --dart-define=GOOGLE_PLACES_PROXY_BASE_URL=$PROXY_URL

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Build successful!"
    echo "📁 Output: build/web"
else
    echo ""
    echo "❌ Build failed!"
    exit 1
fi
