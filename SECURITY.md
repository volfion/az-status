# Security policy

## Reporting a vulnerability

Please do not publish credentials, Keychain contents or router data in a public issue.

Report a suspected security vulnerability privately through GitHub’s security advisory feature:

`https://github.com/volfion/az-status/security/advisories/new`

Include:

- AZ Status version,
- macOS version,
- a description of the impact,
- reproducible steps with secrets removed.

## Supported version

Security fixes are currently provided for the latest published release.

## Data handling

AZ Status communicates with the A-Z Router over the local network. The local password is stored in macOS Keychain. The application does not include analytics or advertising.
