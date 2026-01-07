# CLAUDE.md

This file provides context for AI assistants working with this codebase.

## Project Overview

**Sir Tips-A-Lot** is an iOS tip calculator app built with SwiftUI. It features a modern glassmorphism UI with animated gradients, preset and custom tip percentages, bill splitting, and a tip jar for donations.

## Tech Stack

- **Language:** Swift 5.9+
- **UI Framework:** SwiftUI
- **Target:** iOS 17.6+
- **IDE:** Xcode 15.0+

## Architecture

This project follows **MVVM (Model-View-ViewModel)**:

| Layer | File | Responsibility |
|-------|------|----------------|
| View | `ContentView.swift` | All SwiftUI views and UI components |
| ViewModel | `TipCalculatorViewModel.swift` | Business logic and state management |
| Model | (computed properties) | Tip calculations in ViewModel |

## Key Files

```
TipCal/Tip Calculator/Tip Calculator/
├── Tip_CalculatorApp.swift      # App entry point (@main)
├── ContentView.swift            # Main UI (~780 lines)
│   ├── ContentView             # Main calculator view
│   ├── TipJarView              # Donation sheet
│   ├── AppInfoView             # Version info (tap logo 4x)
│   ├── GlassCard               # Reusable glass effect container
│   ├── TipButton               # Preset tip percentage button
│   ├── CustomTipButton         # Custom tip toggle
│   ├── ResultRow               # Amount display row
│   └── ScaleButtonStyle        # Button press animation
├── TipCalculatorViewModel.swift # Observable state & calculations
└── Assets.xcassets/            # App icons and images
```

## Code Conventions

1. **All new UI must use SwiftUI** — No UIKit
2. **Follow MVVM pattern** with `@Observable` / `ObservableObject`
3. **Prefer structs over classes** for data models
4. **Use `lazy var`** for expensive computed properties in classes
5. **Use `@MainActor`** for ViewModels that publish UI state

## Design Patterns Used

- **Glassmorphism:** `.ultraThinMaterial` + subtle gradients + border strokes
- **Animated backgrounds:** `LinearGradient` with `repeatForever` animation
- **Reusable components:** Generic `GlassCard<Content: View>` wrapper
- **Custom button styles:** `ScaleButtonStyle` for press feedback
- **Sheet presentation:** `.sheet(isPresented:)` for modals

## UI Theme

- **Background:** Dark gradient (RGB ~0.1-0.15 range)
- **Accent color:** `.mint` / `.teal`
- **Typography:** `.rounded` design system fonts
- **Cards:** 20pt corner radius, glass effect with white 0.1 opacity borders

## Commands

### Open in Xcode
```bash
open "TipCal/Tip Calculator/Tip Calculator.xcodeproj"
```

### Build from command line
```bash
xcodebuild -project "TipCal/Tip Calculator/Tip Calculator.xcodeproj" \
  -scheme "Tip Calculator" \
  -destination 'platform=iOS Simulator,name=iPhone 15' \
  build
```

### Version management
```bash
# Check current version
agvtool what-marketing-version

# Set new version
agvtool new-marketing-version 1.1.0
```

### Run unit tests
```bash
# Use any available iOS Simulator (recommended for portability)
xcodebuild test \
  -project "TipCal/Tip Calculator/Tip Calculator.xcodeproj" \
  -scheme "Tip Calculator" \
  -destination 'platform=iOS Simulator,OS=latest,name=iPhone 17 Pro'

# Or use generic destination
xcodebuild test \
  -project "TipCal/Tip Calculator/Tip Calculator.xcodeproj" \
  -scheme "Tip Calculator" \
  -destination generic/platform=iOS\ Simulator
```

## Testing

This project maintains comprehensive unit tests. **All tests must pass before merging any PR.**

### Testing Requirements

1. **All business logic must have unit tests** — ViewModels, Models, and utility functions
2. **Run tests before committing** — Use the pre-commit hook or run manually
3. **Write tests for new features** — Any new calculation logic or data handling needs tests
4. **Maintain test coverage** — Don't remove tests without replacement

### Test Structure

```
TipCal/Tip Calculator/Tip CalculatorTests/
├── TipCalculatorViewModelTests.swift  # ViewModel calculations & state
├── SavedBillTests.swift               # Model encoding/decoding
└── NumberParsingTests.swift           # Receipt scanner parsing
```

### Pre-commit Hook Setup

This project uses [pre-commit](https://pre-commit.com/) for automatic test runs before commits:
```bash
# Install pre-commit (if not already installed)
brew install pre-commit

# Enable hooks for this repo
pre-commit install

# Run manually on all files
pre-commit run --all-files
```

## Easter Egg

Tap the app logo 4 times to reveal the App Info view (version/build number).

## Payment Links (Tip Jar)

Located in `TipJarView` within `ContentView.swift`:
- Venmo: `@NickMacCarthy`
- Cash App: `$NickMacCarthy`
- PayPal: `nickmaccarthy`

## App Store Guidelines Compliance

This app must adhere to Apple's App Store Review Guidelines. Key areas to watch:

### Guideline 5.1.1 - Permission Requests (Privacy)

**DO:**
- Use neutral button text like "Continue" or "Next" before system permission dialogs
- Always proceed to the system permission dialog after any pre-permission messaging
- Let users deny permissions in the **system dialog** (not a custom skip button)
- Use `@Environment(\.openURL)` with `UIApplication.openSettingsURLString` to link to Settings

**DON'T:**
- Use action-oriented text like "Enable Location" or "Allow Camera" on custom buttons
- Provide "Skip", "Maybe Later", or "Not Now" buttons that bypass the system permission dialog
- Create custom permission dialogs that look like system dialogs

**Example (Correct):**
```swift
Button("Continue") {
    locationManager.requestPermission()  // Triggers system dialog
}
```

### Guideline 2.1 - In-App Purchases

When submitting to the App Store:
- All IAP products must be submitted alongside the app binary
- Each IAP requires a **screenshot** in App Store Connect
- IAPs must be marked "Ready to Submit" before app submission

**Current IAP Products:**
| Product ID | Price | Description |
|------------|-------|-------------|
| `nmac.TipCalculator.tip.service.good` | $0.99 | Good Service tip |
| `nmac.TipCalculator.tip.service.great` | $2.99 | Great Service tip |
| `nmac.TipCalculator.tip.service.amazing` | $4.99 | Amazing Service tip |

### Guideline 2.3.3 - Screenshots

- iPhone screenshots must show iPhone UI (not iPad)
- iPad screenshots must show iPad UI (not iPhone in a frame)
- Screenshots must reflect actual app functionality
- Avoid marketing materials that don't show the app in use

**Required Screenshot Sizes:**
| Device | Size (pixels) |
|--------|---------------|
| 6.7" iPhone | 1290 × 2796 |
| 6.5" iPhone | 1284 × 2778 |
| 12.9" iPad Pro | 2048 × 2732 |
| 13" iPad Air/Pro | 2064 × 2752 |

### Pre-Submission Checklist

- [ ] All permission request flows use neutral language ("Continue", "Next")
- [ ] No skip/bypass buttons before system permission dialogs
- [ ] All IAP products have screenshots in App Store Connect
- [ ] IAP products are included in the submission
- [ ] iPhone screenshots taken on iPhone simulator
- [ ] iPad screenshots taken on iPad simulator (not iPhone in frame)
- [ ] All unit tests pass
- [ ] Version and build numbers updated
