# Architecture & Technical Stack

## 🏗️ Architecture Overview

The Art Finance Hub follows a clean, layered architecture designed for cross-platform compatibility and maintainability.

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
│   │   ├── transaction.dart      # Transaction data model with JSON serialization
│   │   ├── project.dart          # Project data model for organizing finances
│   │   └── app_user.dart         # User profile data model
│   ├── services/
│   │   ├── auth_service.dart     # Firebase authentication service
│   │   ├── registration_api_service.dart  # Server-side registration API
│   │   ├── storage_service.dart  # Local storage abstraction layer (project-scoped)
│   │   ├── sync_service.dart     # Abstract interface for transaction sync
│   │   ├── firestore_sync_service.dart  # Firestore implementation of transaction sync
│   │   ├── project_service.dart  # Project CRUD operations service
│   │   ├── project_sync_service.dart  # Abstract interface for project sync
│   │   ├── firestore_project_sync_service.dart  # Firestore implementation of project sync
│   │   ├── migration_service.dart # Data migration to multi-project structure
│   │   └── analytics_service.dart # Financial analytics and insights calculation
│   ├── providers/
│   │   ├── auth_provider.dart    # Authentication state management
│   │   └── project_provider.dart # Project state management
│   ├── screens/
│   │   ├── home_screen.dart      # Main app screen (project-scoped)
│   │   ├── dashboard_screen.dart # Analytics dashboard with charts and insights
│   │   ├── auth/                 # Authentication screens
│   │   │   ├── login_screen.dart
│   │   │   ├── registration_screen.dart
│   │   │   └── email_verification_screen.dart
│   │   └── profile/
│   │       └── profile_screen.dart  # User profile management
│   └── widgets/
│       ├── auth_wrapper.dart     # Authentication state wrapper
│       ├── summary_cards.dart    # Income/Expense/Balance display cards
│       ├── transaction_form.dart # Transaction input form
│       ├── transaction_list.dart # Transaction history list view
│       └── project_drawer.dart   # Project selector with global summary
├── functions/                    # Cloud Functions (Node.js)
│   ├── index.js                  # Function entry points
│   ├── registration_service.js   # Token-based registration logic
│   └── email_templates.js        # Email template generation
├── firestore.rules               # Firestore security rules (user & project data isolation)
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

### Authentication & Backend
- **Firebase Authentication**: User authentication
  - Email link (passwordless) authentication
  - Cross-platform session management
  - Automatic token refresh
- **Cloud Firestore**: NoSQL database
  - User profile storage
  - Real-time sync capability
  - Security rules for user-level access control
- **Cloud Functions**: Serverless backend
  - Token-based registration flow
  - Email notifications
  - Scheduled cleanup jobs

### Data Persistence
- **SharedPreferences**: Local key-value storage
  - Platform-agnostic API
  - Persists data across app sessions
  - JSON serialization for complex objects
- **Cloud Firestore**: Cloud storage for authenticated users
  - User profiles and preferences
  - **Transaction sync across devices** (new!)
  - Real-time data synchronization
  - Automatic offline support

### Data Synchronization
- **Local-First Architecture**: Data is always stored locally first
  - Fast, responsive UI even without network
  - Changes sync to cloud when available
- **Cloud Sync via SyncService**: Abstract interface for backend flexibility
  - `FirestoreSyncService`: Current implementation using Cloud Firestore
  - Easy to swap to different backends (REST API, etc.)
  - Data migration feasible via Firestore export/import
- **Storage Modes**:
  - `localOnly`: Data stored only on device (default for unauthenticated users)
  - `cloudSync`: Data synced to cloud (enabled when authenticated)

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
  - Supports both local-only and cloud-sync modes
  - Testable with mocks
- **Dependency Inversion**: SyncService interface
  - Abstract interface for cloud synchronization
  - Implementations can be swapped without changing consuming code
  - Follows SOLID principles for maintainability

### Widget Composition
- **Reusable Widgets**: Modular UI components
  - SummaryCards: Display financial summaries
  - TransactionForm: Input handling
  - TransactionList: Data display
- **Separation of Concerns**: Each widget has single responsibility

## 🔄 Data Flow

### Local Storage Flow
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

### Cloud Sync Flow (Authenticated Users)
```
User Action (UI)
    ↓
Widget Event Handler
    ↓
State Update (setState)
    ↓
StorageService (local-first)
    ├── Save to SharedPreferences (local)
    └── Sync via SyncService (cloud)
            ↓
        FirestoreSyncService
            ↓
        Cloud Firestore
            ↓
        Synced across devices
```

### Example: Adding a Transaction

1. User fills form and taps "Add Transaction"
2. `TransactionForm` creates `Transaction` object
3. `HomeScreen` receives transaction via callback
4. `HomeScreen` updates local state list
5. `StorageService.saveTransactions()` persists to disk
6. UI rebuilds with new transaction displayed

## 📊 Data Storage Schema

### Project Model
```dart
{
  "id": "uuid-v4-string",
  "name": "My Art Project",
  "createdAt": "2024-01-15T10:30:00.000",
  "deletedAt": null | "2024-06-15T10:30:00.000"
}
```

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

### Local Storage Format (SharedPreferences)
- **Projects**: `'projects'` → JSON-encoded list of project objects
- **Current Project ID**: `'current_project_id'` → string
- **Transactions (per project)**: `'project-finances-{projectId}'` → JSON-encoded list of transactions
- **Legacy Transactions**: `'project-finances'` → migrated to default project

### Cloud Storage Format (Firestore)
```
users/{userId}/
  ├── projects/{projectId}/
  │   ├── name: "My Art Project"
  │   ├── createdAt: Timestamp
  │   ├── deletedAt: Timestamp | null
  │   └── transactions/{transactionId}/
  │       ├── description: string
  │       ├── amount: number
  │       ├── type: "income" | "expense"
  │       ├── category: string
  │       └── date: Timestamp
  └── (legacy) transactions/{transactionId}/  # Pre-migration structure
```

### Data Migration
When upgrading from single-project to multi-project:
1. Legacy transactions from `'project-finances'` key are detected
2. A "Default" project is created with ID `'default'`
3. Legacy transactions are moved to `'project-finances-default'`
4. Original data is backed up to `'project-finances_backup'`
5. Migration is marked complete in `'migration_to_projects_completed'`

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

### Authentication Security
- **Passwordless Authentication**: Email link authentication eliminates password-related vulnerabilities
- **Server-Side Token Verification**: Registration tokens are verified server-side
- **Token Expiration**: 24-hour expiration for registration tokens
- **Single-Use Tokens**: Tokens can only be used once
- **Firestore Security Rules**: User-level access control on all data

### Privacy-First Design
- **Data Minimization**: Only essential user data collected
- **User Control**: Soft delete with 90-day recovery period
- **Privacy-Respecting Analytics**: Grafana Faro tracks usage patterns without PII
- **No Third-Party Data Sharing**: Data stays within Firebase/GCP ecosystem

### Data Protection
- **Encrypted in Transit**: All data encrypted via HTTPS
- **Encrypted at Rest**: Firebase/GCP encrypts stored data
- **Access Control**: Firestore rules enforce user-level data isolation
- **GDPR Considerations**: Built with data protection regulations in mind

## 🔄 Future Architecture Enhancements

### State Management Evolution
- Consider **Provider** or **Riverpod** for:
  - Multiple screens with shared state
  - Complex state dependencies
  - Better testability

### Backend Migration
The `SyncService` interface allows for easy backend migration:
- **Current**: Cloud Firestore via `FirestoreSyncService`
- **Alternative Options**:
  - REST API implementation
  - GraphQL implementation
  - Other cloud providers
- **Migration Process**:
  1. Export data from Firestore using Firebase Admin SDK
  2. Transform data format if needed
  3. Import to new backend
  4. Implement new `SyncService`
  5. Update app to use new implementation

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
