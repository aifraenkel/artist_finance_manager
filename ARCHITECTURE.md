# Architecture & Technical Stack

## 🏗️ Architecture Overview

The Artist Finance Manager follows a clean, layered architecture designed for cross-platform compatibility and maintainability.

### Architecture Layers

```
┌─────────────────────────────────────┐
│         Presentation Layer          │
│     (Screens & Widgets)             │
├─────────────────────────────────────┤
│         Business Logic              │
│         (Models)                    │
├─────────────────────────────────────┤
│         Data Layer                  │
│         (Services)                  │
└─────────────────────────────────────┘
```

## 📂 Project Structure

```
artist_finance_manager/
├── lib/
│   ├── main.dart                 # App entry point & MaterialApp configuration
│   ├── models/
│   │   └── transaction.dart      # Transaction data model with JSON serialization
│   ├── services/
│   │   └── storage_service.dart  # Local storage abstraction layer
│   ├── screens/
│   │   └── home_screen.dart      # Main app screen (stateful widget)
│   └── widgets/
│       ├── summary_cards.dart    # Income/Expense/Balance display cards
│       ├── transaction_form.dart # Transaction input form
│       └── transaction_list.dart # Transaction history list view
├── test/                         # All test files
├── android/                      # Android platform-specific files
├── ios/                          # iOS platform-specific files
├── web/                          # Web platform-specific files
└── pubspec.yaml                  # Flutter dependencies and configuration
```

## 🔧 Technology Stack

### Framework & Language
- **Flutter 3.x**: Cross-platform UI framework
  - Single codebase for iOS, Android, and Web
  - Hot reload for rapid development
  - Rich widget library
- **Dart**: Programming language
  - Strong typing with null safety
  - Async/await support
  - Modern language features

### UI Components
- **Material Design 3**: Modern UI design system
  - Consistent look and feel across platforms
  - Adaptive components
  - Theme support (light mode with dark mode ready)

### Data Persistence
- **SharedPreferences**: Local key-value storage
  - Platform-agnostic API
  - Persists data across app sessions
  - JSON serialization for complex objects

### Platform-Specific Storage
- **iOS/Android**: Native SharedPreferences
  - NSUserDefaults on iOS
  - SharedPreferences on Android
- **Web**: Browser LocalStorage
  - Persistent browser storage
  - Same API across all platforms

### Utilities
- **Intl**: Internationalization and date/time formatting
  - Date formatting (MM/dd/yyyy)
  - Time formatting (HH:mm)
  - Currency formatting ready

## 🎯 Design Patterns

### State Management
- **StatefulWidget**: Built-in Flutter state management
  - Simple and effective for single-screen app
  - setState() for UI updates
  - Ready to migrate to Provider/Riverpod if needed

### Data Model
- **Immutable Models**: Transaction class with copyWith pattern
- **JSON Serialization**: Manual toJson/fromJson methods
- **Type Safety**: Enums for transaction types and categories

### Service Layer
- **Repository Pattern**: StorageService abstracts data persistence
  - Single source of truth for data operations
  - Easy to swap implementations (local → cloud)
  - Testable with mocks

### Widget Composition
- **Reusable Widgets**: Modular UI components
  - SummaryCards: Display financial summaries
  - TransactionForm: Input handling
  - TransactionList: Data display
- **Separation of Concerns**: Each widget has single responsibility

## 🔄 Data Flow

```
User Action (UI)
    ↓
Widget Event Handler
    ↓
State Update (setState)
    ↓
Storage Service
    ↓
SharedPreferences (Platform-specific)
    ↓
UI Rebuild
```

### Example: Adding a Transaction

1. User fills form and taps "Add Transaction"
2. `TransactionForm` creates `Transaction` object
3. `HomeScreen` receives transaction via callback
4. `HomeScreen` updates local state list
5. `StorageService.saveTransactions()` persists to disk
6. UI rebuilds with new transaction displayed

## 📊 Data Storage Schema

### Transaction Model
```dart
{
  "id": "uuid-v4-string",
  "type": "expense" | "income",
  "category": "venue" | "musicians" | "materials" | ...,
  "description": "string",
  "amount": 123.45,
  "date": "2024-01-15T10:30:00.000"
}
```

### Storage Format
Transactions are stored as JSON array in SharedPreferences:
- **Key**: `'transactions'`
- **Value**: JSON-encoded list of transaction objects

## 🚀 Platform Considerations

### Cross-Platform Strategy
- **Write Once, Run Everywhere**: 95%+ code shared
- **Platform Channels**: Ready for native integrations if needed
- **Responsive Design**: Adapts to different screen sizes

### Web-Specific
- **HTML Renderer vs CanvasKit**: Supports both
- **URL Strategy**: Hash-based routing (default)
- **PWA Ready**: Can be installed as Progressive Web App

### Mobile-Specific
- **iOS**: Minimum iOS 11.0, CocoaPods for dependencies
- **Android**: Minimum API 21 (Android 5.0)
- **Permissions**: No special permissions required (local storage only)

## 🧪 Testing Strategy

The app uses multiple testing approaches for comprehensive coverage:

- **Unit Tests**: Models and services logic
- **Widget Tests**: UI component behavior
- **Integration Tests**: Complete user flows
- **E2E Tests**: Real browser testing

See [TEST_GUIDE.md](TEST_GUIDE.md) for detailed testing documentation.

## 🔐 Security & Privacy

### Privacy-First Design
- **No Backend**: All data stays on device
- **No Analytics**: No tracking or data collection
- **No Network Calls**: Completely offline-capable
- **Local Storage Only**: User has full control

### Future Backend Considerations
When/if backend sync is added:
- End-to-end encryption for data in transit
- User authentication (Firebase Auth, Supabase Auth)
- Row-level security for multi-user scenarios
- GDPR compliance for data handling

## 🔄 Future Architecture Enhancements

### State Management Evolution
- Consider **Provider** or **Riverpod** for:
  - Multiple screens with shared state
  - Complex state dependencies
  - Better testability

### Data Layer Evolution
- **Repository Pattern Extension**:
  - `LocalDataSource` (current SharedPreferences)
  - `RemoteDataSource` (future backend)
  - `Repository` (coordination layer with sync logic)

### Modularization
- Break into feature modules:
  - `features/transactions/`
  - `features/analytics/`
  - `features/projects/`
- Shared core module for common code

## 📚 Additional Resources

- [Flutter Architecture Samples](https://github.com/brianegan/flutter_architecture_samples)
- [Material Design 3](https://m3.material.io/)
- [Flutter Best Practices](https://flutter.dev/docs/development/best-practices)
- [Effective Dart](https://dart.dev/guides/language/effective-dart)
