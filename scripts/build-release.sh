#!/bin/bash
set -euo pipefail

VERSION="${1:-1.4}"
ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$ROOT_DIR/build"
DIST_DIR="$ROOT_DIR/dist"
APP_NAME="AZ Status"
APP_PATH="$BUILD_DIR/Build/Products/Release/$APP_NAME.app"
DMG_PATH="$DIST_DIR/AZ-Status-$VERSION.dmg"

rm -rf "$BUILD_DIR" "$DIST_DIR"
mkdir -p "$DIST_DIR"

xcodebuild   -project "$ROOT_DIR/AZRouterMenu.xcodeproj"   -target "$APP_NAME"   -configuration Release   -derivedDataPath "$BUILD_DIR"   CODE_SIGNING_ALLOWED=NO   MARKETING_VERSION="$VERSION"   CURRENT_PROJECT_VERSION="${GITHUB_RUN_NUMBER:-14}"   clean build

# Ad-hoc signing keeps the bundle internally consistent but is not Developer ID signing or notarization.
codesign --force --deep --sign - "$APP_PATH"

"$ROOT_DIR/scripts/create-dmg.sh" "$APP_PATH" "$DMG_PATH"

shasum -a 256 "$DMG_PATH" | tee "$DMG_PATH.sha256"
echo "Created: $DMG_PATH"
