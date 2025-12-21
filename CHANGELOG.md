# Changelog

All notable changes to Sir Tips-A-Lot will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Planned
- Apple Watch companion app
- Widget support
- Receipt scanning with OCR
- Tip history tracking

---

## [1.0.0] - 2024-12-21

### Added
- Initial release of Sir Tips-A-Lot
- Bill amount entry with decimal keyboard
- Preset tip buttons: 18%, 20%, 25%
- Custom tip percentage input
- Round up tip to nearest dollar toggle
- Split bill between multiple people (stepper control)
- Results display showing:
  - Tip amount
  - Subtotal
  - Total
  - Per-person amount (when splitting)
- Modern dark UI with animated gradient background
- Glassmorphism card design
- Tip Jar feature with Venmo, Cash App, and PayPal links
- Easter egg: Tap logo 4x to show version info
- Keyboard dismiss with "Done" button and tap-to-dismiss
- Custom app icon (Sir Tips-A-Lot mascot)
- In-app logo display

### Technical
- Built with SwiftUI
- MVVM architecture with ObservableObject
- iOS 17.0+ support
- Auto-increment build number script

---

## Version History

| Version | Date | Highlights |
|---------|------|------------|
| 1.0.0 | 2024-12-21 | Initial release |

---

## How to Update This File

When making changes, add entries under `[Unreleased]` in these categories:

- **Added** — New features
- **Changed** — Changes in existing functionality
- **Deprecated** — Soon-to-be removed features
- **Removed** — Removed features
- **Fixed** — Bug fixes
- **Security** — Vulnerability fixes

When releasing, move `[Unreleased]` items to a new version section with the date.

