# Sir Tips-A-Lot 🎩💰

A beautiful, modern tip calculator app for iOS built with SwiftUI.

This is my first IOS application. 

![iOS](https://img.shields.io/badge/iOS-17.0+-blue.svg)
![Swift](https://img.shields.io/badge/Swift-5.9-orange.svg)
![License](https://img.shields.io/badge/License-MIT-green.svg)

## Features

- 💵 **Quick Tip Calculation** — Enter your bill and instantly see the tip
- 🎯 **Preset Tip Percentages** — 18%, 20%, 25% with one tap
- ⚙️ **Custom Tip** — Enter any percentage you want
- 📈 **Round Up Tip** — Round your tip to the nearest dollar
- 👥 **Split the Bill** — Divide among any number of people
- 🌙 **Beautiful Dark UI** — Modern glassmorphism design with animated gradients
- ❤️ **Tip Jar** — Support the developer via Venmo, Cash App, or PayPal

## Screenshots

<p align="center">
  <img src="screenshots/1.png" width="250" alt="Main Screen" />
  <img src="screenshots/2.png" width="250" alt="Tip Calculation" />
  <img src="screenshots/3.png" width="250" alt="Split Bill" />
</p>

| Main Screen | Tip Calculation | Split Bill |
|:-----------:|:---------------:|:----------:|
| Enter your bill amount | See tip and total instantly | Split between multiple people |

## Requirements

- iOS 17.0+
- Xcode 15.0+
- Swift 5.9+

## Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/sir-tips-a-lot.git
   ```

2. Open the project in Xcode:
   ```bash
   cd sir-tips-a-lot
   open "TipCal/Tip Calculator/Tip Calculator.xcodeproj"
   ```

3. Build and run on your device or simulator

## Project Structure

```
TipCal/Tip Calculator/Tip Calculator/
├── Tip_CalculatorApp.swift      # App entry point
├── ContentView.swift            # Main UI with all views
├── TipCalculatorViewModel.swift # MVVM ViewModel
├── Assets.xcassets/             # Images and colors
│   ├── AppIcon.appiconset/      # App icons
│   └── InAppLogo.imageset/      # In-app logo
└── scripts/
    └── increment_build.sh       # Auto-increment build number
```

## Architecture

This app follows the **MVVM (Model-View-ViewModel)** pattern:

- **View** (`ContentView.swift`) — SwiftUI views and UI components
- **ViewModel** (`TipCalculatorViewModel.swift`) — Business logic and state management
- **Model** — Simple computed properties for tip calculations

## Customization

### Payment Links (Tip Jar)

To use your own payment links, update these variables in `ContentView.swift`:

```swift
let venmoUsername = "YourVenmoUsername"
let cashAppUsername = "$YourCashTag"
let paypalUsername = "YourPayPalUsername"
```

### App Icon

Replace the images in `Assets.xcassets/AppIcon.appiconset/` with your own 1024x1024 icon.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Author

**Nick MacCarthy**
- Email: nickmaccarthy@gmail.com
- Venmo: @NickMacCarthy

## Acknowledgments

- Built with SwiftUI
- Icons from SF Symbols
- Inspired by the need for a beautiful, simple tip calculator

---

*"They like big tips and they cannot lie"* 🍸

