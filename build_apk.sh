#!/usr/bin/env bash
# Build release APK using the user-local Android SDK (system SDK at /opt is read-only).
# Usage: ./build_apk.sh
set -e

ANDROID_LOCAL_SDK="/home/david/Android/Sdk"

# Keep local.properties pointing at the writable SDK so Gradle can install components.
sed -i "s|^sdk.dir=.*|sdk.dir=${ANDROID_LOCAL_SDK}|" android/local.properties

ANDROID_HOME="$ANDROID_LOCAL_SDK" \
ANDROID_SDK_ROOT="$ANDROID_LOCAL_SDK" \
flutter build apk --release "$@"

echo ""
echo "APK: build/app/outputs/flutter-apk/app-release.apk"
