#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
export JAVA_HOME="${JAVA_HOME:-/usr/lib/jvm/java-17-openjdk-amd64}"
export PATH="$JAVA_HOME/bin:$PATH"

API_URL="${API_BASE_URL:-}"
DEFINES_FILE="android/dart_defines.release.json"

if [[ -n "$API_URL" ]]; then
  flutter build appbundle --release --obfuscate --split-debug-info=build/app/outputs/symbols \
    --dart-define=API_BASE_URL="$API_URL"
elif [[ -f "$DEFINES_FILE" ]]; then
  echo "Using $DEFINES_FILE"
  flutter build appbundle --release --obfuscate --split-debug-info=build/app/outputs/symbols \
    --dart-define-from-file="$DEFINES_FILE"
else
  echo "Set API_BASE_URL to your HTTPS API, e.g.:"
  echo "  API_BASE_URL=https://api.example.com ./tool/build_play.sh"
  exit 1
fi

echo
echo "AAB: build/app/outputs/bundle/release/app-release.aab"
