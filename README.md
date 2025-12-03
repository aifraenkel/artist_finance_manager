# Art Finance Hub 🎨💰

A cross-platform finance tracker app for artists to manage project income and expenses. Built with Flutter to run on iOS, Android, and Web.

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=flat&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=flat&logo=dart&logoColor=white)

## 📱 Overview

The goal of this app is to enable artists to easily manage costs and income from their art projects. Track expenses and income in real-time with a beautiful, intuitive interface that works on all your devices.

## ✨ Features

### 🔐 Authentication & User Management
- **Passwordless Sign-In**: Secure email link authentication (no passwords to remember)
- **Server-Side Token Verification**: Backend-verified registration tokens for enhanced security
- **Cross-Device Authentication**: Start registration on one device, complete on another
- **User Profile Management**: Update profile information and manage account settings
- **Soft Delete with Recovery**: 90-day recovery period for deleted accounts
- **Session Persistence**: Stay logged in across app restarts

### 💰 Finance Management
- **Track Expenses**: Record art-related costs (venue, musicians, materials, food & drinks, book printing, podcast, etc.)
- **Track Income**: Log revenue from book sales, event tickets, and more
- **Real-time Summary**: View income, expenses, and balance at a glance
- **Transaction History**: View all transactions in chronological order with category, description, date, and amount

### 📱 Cross-Platform Experience
- **Works Everywhere**: iOS, Android, and Web from a single codebase
- **Responsive Design**: Beautiful UI that adapts to any screen size
- **Offline-First**: Local storage for fast access, with cloud sync capability

### ☁️ Cloud Sync (Authenticated Users)
- **Cross-Device Access**: Access your financial data from any device
- **Automatic Sync**: Transactions automatically sync when connected
- **Data Isolation**: Your data is securely isolated from other users
- **Local-First**: Works offline, syncs when connectivity is restored
- **Manual Refresh**: Sync button to force refresh from cloud

### 📊 Observability (Web)
- **Performance Monitoring**: Track load times and Web Vitals via Grafana Faro
- **Error Tracking**: Automatic JavaScript error capture and logging
- **Usage Analytics**: Understand feature usage patterns (privacy-respecting)

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

**Note:** With user authentication, your data is stored securely in the cloud and syncs across all your devices. For local-only usage without signing in, data is stored locally on each device.

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

For detailed setup instructions, see [SETUP_GUIDE.md](docs/SETUP_GUIDE.md).

**Quick start:**

1. **Clone the repository**
   ```bash
   git clone https://github.com/aifraenkel/artist_finance_manager.git
   cd artist_finance_manager
   ```

2. **Install Flutter dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the app**
   ```bash
   flutter run -d chrome  # For web
   ```

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
```

## 🚀 Deployment

The app is automatically deployed to Google Cloud Run when code is merged to `main`. See [DEPLOYMENT.md](docs/DEPLOYMENT.md) for full documentation.

### Quick Deploy Commands

```bash
# Deploy to GCP Cloud Run (one command)
./scripts/deploy.sh

# Rollback to previous version
./scripts/rollback.sh
```

**Automatic CI/CD**: Every push to `main` triggers:
1. ✅ All tests (unit, widget, integration, E2E)
2. 🏗️ Build Flutter web app
3. 🐳 Build and push Docker image
4. 🚀 Deploy to Cloud Run
5. 🏥 Health checks and smoke tests

For detailed deployment setup, configuration, and troubleshooting, see [docs/DEPLOYMENT.md](docs/DEPLOYMENT.md).

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

## 🏗️ Architecture & Tech Stack

The app is built with Flutter 3.x and uses a clean layered architecture with local-first data storage. For detailed information about the project structure, technology stack, design patterns, and architecture decisions, see [ARCHITECTURE.md](docs/ARCHITECTURE.md).

## 📊 Observability with Grafana Cloud

The web version includes **Grafana Faro** integration for real-time observability:

### What's Tracked
- **Custom Events**: Transaction additions/deletions, page loads
- **Performance Metrics**: Load times, Web Vitals (LCP, FID, CLS)
- **Error Tracking**: JavaScript errors, storage failures
- **User Sessions**: Session duration and behavior
- **Console Logs**: Application logging

### Setup
1. Create a free Grafana Cloud account at [grafana.com](https://grafana.com)
2. Follow the detailed setup guide in [GRAFANA_SETUP.md](docs/GRAFANA_SETUP.md)
3. Configure your Faro collector URL in `web/index.html`
4. Build and deploy - observability is automatic!

### Benefits
- Monitor real-time user activity
- Track and fix errors proactively
- Analyze performance bottlenecks
- Understand feature usage patterns

**Note**: Observability is currently web-only. Mobile platforms use a no-op implementation.

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

This project has comprehensive test coverage including unit tests, widget tests, integration tests, and E2E browser tests. For detailed testing documentation, see [TEST_GUIDE.md](docs/TEST_GUIDE.md).

**Quick start:**
```bash
# Run all unit and widget tests
flutter test

# Run E2E widget tests (fast, all platforms)
flutter test test/e2e_widget/

# Run E2E web tests (browser)
cd test/e2e_web && ./run-e2e-tests.sh
```
---

📄 This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
🤝 Contributions, issues, and feature requests are welcome!
💡 If you found this helpful, please give it a ⭐️!


Built with ❤️ for artists everywhere
