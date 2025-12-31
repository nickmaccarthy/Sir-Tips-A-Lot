# Changelog

All notable changes to Sir Tips-A-Lot will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Planned
- Apple Watch companion app
- Widget support
- Tip history export

---

## [1.1.0] - 2024-12-30

### Added
- **Receipt Scanning** — Camera-based OCR to auto-populate bill amounts
  - Smart detection of subtotal, total, and pre-included gratuity
  - Enhanced Vision scanner option in settings
- **Sentiment-Based Tipping** — Rate service with customizable emojis
  - 😢 Meh / 😐 OK / 🤩 Great with personalized tip percentages
  - Custom emoji selection via emoji keyboard
- **Location Intelligence** — Auto-saves restaurant name with bills
  - Reverse geocoding via CoreLocation
  - Privacy-first design (data stays on device)
  - Location onboarding flow for first-time users
  - Manual location picker option
- **Bill History Enhancements**
  - Expandable bill details with notes, location, and sentiment
  - Edit saved bills anytime
  - Lifetime stats footer (total tips & total spent)
  - Notes field for personal reminders
- **Multi-Currency Support** — USD, EUR, GBP, CAD, AUD, JPY, CHF, MXN, INR
- **Settings Screen** — Customizable preferences
  - Adjust tip percentages for each sentiment
  - Change sentiment emojis
  - Currency selection
  - Location toggle
  - Round up tip by default option
  - Enhanced scanner toggle
- **Splash Screen** — Branded launch experience with animation
- **Quick Reset Button** — Clear current calculation instantly
- **Pre-included Gratuity Detection** — Smart handling when tip is already on bill

### Changed
- Tip buttons replaced with sentiment-based emoji selection
- Bill history now shows tip amount in currency below percentage
- Improved keyboard handling with Done button

### Technical
- Added comprehensive unit tests for ViewModel, Models, and parsing
- Pre-commit hooks for automated testing
- LocationManager service for CoreLocation integration
- StoreManager for in-app purchase support

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
| 1.1.0 | 2024-12-30 | Receipt scanning, sentiment tipping, location, multi-currency |
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
