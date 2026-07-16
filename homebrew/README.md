# Homebrew tap setup

Create a second GitHub repository named `homebrew-tap` under the `volfion` account.

Copy `Casks/az-status.rb` into that repository and replace the SHA-256 placeholder with the checksum of the release DMG:

```bash
shasum -a 256 AZ-Status-1.4.dmg
```

Users can then install with:

```bash
brew tap volfion/tap
brew install --cask az-status
```

For later versions, update both `version` and `sha256`.
