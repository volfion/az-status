# AZ Status

**AZ Status** is a lightweight native macOS menu-bar application for real-time monitoring of an A-Z Router on the local network.

> Community project by **Ondřej Vlček** (`volfion`). AZ Status is not affiliated with or endorsed by A-Z TRADERS s.r.o.

## Features

- Current PV production directly in the macOS menu bar
- Optional icon + power, icon only, or power only
- Monochrome or state-colored menu-bar icon
- Production, house load, EV charging, battery, grid flow and temperatures
- Compact real-time energy-flow diagram
- Czech, English, German, Slovak and Polish UI
- Configurable refresh interval from 5 seconds to 5 minutes
- Optional connection-loss and reconnection notifications
- Password stored in macOS Keychain
- Local communication with `http://azrouter.local`
- Menu-bar-only app — no Dock icon
- Optional launch at login

## Requirements

- macOS 13 Ventura or newer
- A-Z Router reachable as `http://azrouter.local`
- Local A-Z Router credentials

## Installation

### GitHub Release / DMG

1. Download `AZ-Status-1.4.dmg` from the Releases page.
2. Open the image and copy **AZ Status.app** to **Applications**.
3. Because version 1.4 is currently distributed without Apple notarization, macOS may block the first launch. Open **System Settings → Privacy & Security** and choose **Open Anyway**, or Control-click the app and choose **Open**.
4. Enter the local A-Z Router password when prompted.

### Build from source

1. Open `AZRouterMenu.xcodeproj` in Xcode.
2. Select the **AZ Status** target and your Personal Team under **Signing & Capabilities**.
3. Choose **Product → Clean Build Folder**.
4. Build or run with `⌘B` / `⌘R`.

### Homebrew tap

A cask template is included in `homebrew/Casks/az-status.rb`. Once the release DMG is uploaded and its SHA-256 is inserted, users can install from a tap:

```bash
brew tap volfion/tap
brew install --cask az-status
```

## Creating a local unsigned DMG

On a Mac with Xcode installed:

```bash
./scripts/build-release.sh 1.4
```

The resulting files are placed in `dist/`. The build is ad-hoc signed, not notarized.

## GitHub release automation

Push a tag such as `v1.4`. The workflow in `.github/workflows/release.yml` builds the app on a GitHub-hosted macOS runner, creates an ad-hoc-signed DMG and attaches it to a GitHub Release.

## Privacy

AZ Status has no analytics and no remote account. See [PRIVACY.md](PRIVACY.md).

## License

MIT License. See [LICENSE](LICENSE).
