#!/bin/bash
set -euo pipefail

APP_PATH="${1:?Usage: create-dmg.sh /path/to/AZ\ Status.app output.dmg}"
DMG_PATH="${2:?Usage: create-dmg.sh /path/to/AZ\ Status.app output.dmg}"
STAGING="$(mktemp -d)"
trap 'rm -rf "$STAGING"' EXIT

APP_NAME="$(basename "$APP_PATH")"
ditto "$APP_PATH" "$STAGING/$APP_NAME"
ln -s /Applications "$STAGING/Applications"

mkdir -p "$(dirname "$DMG_PATH")"
rm -f "$DMG_PATH"
hdiutil create   -volname "AZ Status"   -srcfolder "$STAGING"   -ov   -format UDZO   "$DMG_PATH"
