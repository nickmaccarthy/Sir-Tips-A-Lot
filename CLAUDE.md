# CLAUDE.md

This file provides context for AI assistants working with this codebase.

## Project Overview

**Sir Tips-A-Lot** is an iOS tip calculator app built with SwiftUI. It features a modern glassmorphism UI with animated gradients, preset and custom tip percentages, bill splitting, and a tip jar for donations.

## Tech Stack

- **Language:** Swift 5.9+
- **UI Framework:** SwiftUI
- **Target:** iOS 17.0+
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

## Easter Egg

Tap the app logo 4 times to reveal the App Info view (version/build number).

## Payment Links (Tip Jar)

Located in `TipJarView` within `ContentView.swift`:
- Venmo: `@NickMacCarthy`
- Cash App: `$NickMacCarthy`
- PayPal: `nickmaccarthy`

