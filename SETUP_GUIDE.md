# Quick Setup Guide

## Prerequisites

1. Install Flutter: https://flutter.dev/docs/get-started/install
2. Verify installation: `flutter doctor`

## Running the App

### Web (Easiest)
```bash
flutter pub get
flutter run -d chrome
```

### iOS
```bash
flutter pub get
open -a Simulator  # Start iOS Simulator
flutter run
```

### Android
```bash
flutter pub get
# Start Android emulator from Android Studio
flutter run
```

## Common Issues

### "No devices found"
- For web: Install Chrome
- For iOS: Open Xcode and install simulators
- For Android: Open Android Studio and create an AVD

### Dependencies error
```bash
flutter clean
flutter pub get
```

### iOS CocoaPods error
```bash
cd ios
pod install
cd ..
flutter run
```

## Building for Production

### Web
```bash
flutter build web --release
# Deploy build/web/ folder
```

### Android APK
```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

### iOS
```bash
flutter build ios --release
open ios/Runner.xcworkspace  # Configure signing in Xcode
```

## Testing

Run all tests:
```bash
flutter test
```

## Need Help?

Check the main [README.md](README.md) for detailed documentation.
