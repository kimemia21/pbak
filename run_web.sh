#!/bin/bash

# Flutter Web Run Script (Chrome + Verbose)
# Usage: ./run_web_chrome.sh

PROXY_URL="http://167.99.202.246:5020/api/v1/places"
WEB_PORT=8080

echo "🚀 Running Flutter Web on Chrome (verbose)"
echo "🌐 Web port: $WEB_PORT"
echo "📍 Proxy URL: $PROXY_URL"
echo ""

flutter run -d chrome -v \
  --web-port=$WEB_PORT \
  --dart-define=GOOGLE_PLACES_PROXY_BASE_URL=$PROXY_URL

EXIT_CODE=$?

if [ $EXIT_CODE -eq 0 ]; then
    echo ""
    echo "✅ Flutter run exited cleanly"
else
    echo ""
    echo "❌ Flutter run exited with errors (code: $EXIT_CODE)"
    exit $EXIT_CODE
fi
