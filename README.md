# Artist Finance Manager 🎨💰

A cross-platform finance tracker app for artists to manage project income and expenses. Built with Flutter to run on iOS, Android, and Web.

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=flat&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=flat&logo=dart&logoColor=white)

## 📱 Overview

The goal of this app is to enable artists to easily manage costs and income from their art projects. Track expenses and income in real-time with a beautiful, intuitive interface that works on all your devices.

## ✨ Features

- 💸 **Track Expenses**: Record art-related costs (venue, musicians, materials, food & drinks, book printing, podcast, etc.)
- 💰 **Track Income**: Log revenue from book sales, event tickets, and more
- 📊 **Real-time Summary**: View income, expenses, and balance at a glance
- 📱 **Cross-Platform**: Works on iOS, Android, and Web
- 💾 **Local Storage**: All data stored locally on your device (no backend required)
- 🎨 **Beautiful UI**: Modern, responsive design that adapts to any screen size
- 🔒 **Privacy First**: Your financial data never leaves your device

## 🚀 Demo the App

The app can be demoed in multiple ways:

### Web Browser (Easiest for Quick Demo)
- Run on your laptop or desktop browser
- Also works on mobile browsers (iPhone/Android)
- Perfect for sharing with others

### Mobile Apps
- Build and install on iOS devices (iPhone/iPad)
- Build and install on Android devices
- Full native app experience

**Note:** Data is stored locally in each platform, so your transactions won't sync between devices. This is perfect for demos and personal use without needing a backend server.

## 📋 Prerequisites

Before you begin, ensure you have the following installed:

1. **Flutter SDK** (3.0.0 or higher)
   - Download from [flutter.dev](https://flutter.dev/docs/get-started/install)
   - Add Flutter to your PATH

2. **Platform-Specific Requirements:**

   **For iOS Development:**
   - macOS computer
   - Xcode 14.0 or higher
   - CocoaPods (`sudo gem install cocoapods`)

   **For Android Development:**
   - Android Studio
   - Android SDK (API level 21 or higher)
   - Java Development Kit (JDK)

   **For Web Development:**
   - Chrome browser (for testing)
   - Any modern web browser for deployment

## 🛠️ Installation & Setup

1. **Clone the repository**
   ```bash
   git clone https://github.com/aifraenkel/artist_finance_manager.git
   cd artist_finance_manager
   ```

2. **Install Flutter dependencies**
   ```bash
   flutter pub get
   ```

3. **Verify your Flutter installation**
   ```bash
   flutter doctor
   ```
   Fix any issues reported by Flutter Doctor before proceeding.

## 🏃‍♂️ Running the App

### Web Browser (Best for Demos)

```bash
# Run in Chrome
flutter run -d chrome

# Or build for production and serve
flutter build web
# Then serve the build/web directory with any web server
```

### iOS (iPhone/iPad)

```bash
# List available iOS simulators
flutter devices

# Run on iOS simulator
flutter run -d "iPhone 15 Pro"

# Or run on physical device (requires Apple Developer account)
flutter run -d <your-device-id>
```

### Android

```bash
# List available Android devices/emulators
flutter devices

# Run on Android emulator or device
flutter run -d <device-id>
```

## 📦 Building Release Versions

### Web

```bash
flutter build web --release

# Output will be in build/web/
# Deploy this folder to any static hosting service:
# - Firebase Hosting
# - Netlify
# - Vercel
# - GitHub Pages
# - AWS S3
```

### iOS App

```bash
flutter build ios --release

# Open in Xcode to configure signing and upload to App Store
open ios/Runner.xcworkspace
```

### Android APK

```bash
# Build APK for direct installation
flutter build apk --release

# Output: build/app/outputs/flutter-apk/app-release.apk

# Or build App Bundle for Google Play Store
flutter build appbundle --release
```

## 🎯 Usage Guide

### Adding a Transaction

1. Select the **Type** (Expense or Income)
2. Choose a **Category** from the dropdown
3. Enter a **Description** (what is this for?)
4. Enter the **Amount** in dollars
5. Click **Add Transaction**

### Viewing Summary

The top cards show:
- 🟢 **Total Income**: All money earned
- 🔴 **Total Expenses**: All money spent
- 🔵 **Balance**: Income minus expenses

### Managing Transactions

- View all transactions in chronological order
- Each transaction shows category, description, date, time, and amount
- Delete any transaction by clicking the **Delete** button

## 📂 Project Structure

```
artist_finance_manager/
├── lib/
│   ├── main.dart                 # App entry point
│   ├── models/
│   │   └── transaction.dart      # Transaction data model
│   ├── services/
│   │   └── storage_service.dart  # Local storage service
│   ├── screens/
│   │   └── home_screen.dart      # Main app screen
│   └── widgets/
│       ├── summary_cards.dart    # Income/Expense/Balance cards
│       ├── transaction_form.dart # Add transaction form
│       └── transaction_list.dart # Transaction history list
├── android/                      # Android platform files
├── ios/                          # iOS platform files
├── web/                          # Web platform files
├── pubspec.yaml                  # Dependencies
└── README.md                     # This file
```

## 🔧 Technologies Used

- **Flutter 3.x**: Cross-platform UI framework
- **Dart**: Programming language
- **SharedPreferences**: Local data persistence
- **Material Design 3**: Modern UI components
- **Intl**: Date/time formatting

## 📊 Data Storage

The app uses platform-specific local storage:

- **iOS/Android**: SharedPreferences (native key-value storage)
- **Web**: Browser LocalStorage

Data is stored as JSON and automatically saved when you add or delete transactions.

## 🐛 Troubleshooting

### "Flutter command not found"
Add Flutter to your PATH. See [Flutter installation guide](https://flutter.dev/docs/get-started/install).

### iOS build fails
```bash
cd ios
pod install
cd ..
flutter clean
flutter pub get
flutter run -d ios
```

### Android build fails
```bash
flutter clean
flutter pub get
flutter run -d android
```

### Web version not loading
```bash
flutter clean
flutter pub get
flutter run -d chrome
```

## 🧪 Testing

This project has comprehensive test coverage with three test types, see [test/README.md](test/README.md) for detailed testing documentation.

**Quick start:**
```bash
# Run E2E widget tests (fast, all platforms)
flutter test test/e2e_widget/

# Run integration tests (requires device/simulator)
flutter test test/integration_test/

# Run E2E web tests (browser)
cd test/e2e_web && ./run-e2e-tests.sh

# Clean test artifacts
cd test && ./clean-test-artifacts.sh
```
---

📄 This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
🤝 Contributions, issues, and feature requests are welcome!
💡 If you found this helpful, please give it a ⭐️!


Built with ❤️ for artists everywhere
