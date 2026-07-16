#!/bin/bash
set -euo pipefail
VERSION="${1:?Version required, e.g. 1.4}"
DMG="${2:?DMG path required}"
SHA="$(shasum -a 256 "$DMG" | awk '{print $1}')"
cat <<EOF
cask "az-status" do
  version "$VERSION"
  sha256 "$SHA"

  url "https://github.com/volfion/az-status/releases/download/v#{version}/AZ-Status-#{version}.dmg"
  name "AZ Status"
  desc "Real-time A-Z Router monitoring in the macOS menu bar"
  homepage "https://github.com/volfion/az-status"

  depends_on macos: ">= :ventura"

  app "AZ Status.app"

  zap trash: [
    "~/Library/Preferences/cz.volfion.AZStatus.plist",
  ]
end
EOF
