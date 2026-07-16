cask "az-status" do
  version "1.4"
  sha256 "REPLACE_WITH_SHA256_FROM_RELEASE_DMG"

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
