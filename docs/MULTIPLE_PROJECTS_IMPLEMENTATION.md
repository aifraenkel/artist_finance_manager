# Multiple Projects Implementation Summary

## Overview

This document summarizes the implementation of multiple projects support in the Art Finance Hub application.

## Date

December 3, 2025

## Changes Made

### 1. Data Models

**Created `lib/models/project.dart`:**
- Project model with `id`, `name`, `createdAt`, and `deletedAt` fields
- Soft-delete support via `deletedAt` timestamp
- JSON serialization for local storage
- Firestore serialization for cloud sync
- Equality and copyWith methods

### 2. Services

**Created `lib/services/project_service.dart`:**
- CRUD operations for projects (create, read, update, delete)
- Current project ID management
- Default project creation and management
- Local storage using SharedPreferences

**Created `lib/services/project_sync_service.dart`:**
- Abstract interface for project cloud sync
- Consistent with existing SyncService pattern
- Exception handling with ProjectSyncException

**Created `lib/services/firestore_project_sync_service.dart`:**
- Firestore implementation of ProjectSyncService
- Projects stored at: `users/{userId}/projects/{projectId}`
- Batch operations for efficiency
- Sync metadata tracking

**Created `lib/services/migration_service.dart`:**
- Automatic migration from single-project to multi-project structure
- Moves legacy transactions to "Default" project
- Backup mechanism for safety
- One-time execution with completion tracking

**Updated `lib/services/storage_service.dart`:**
- Made project-aware with `setProjectId()` method
- Storage keys now include project ID: `project-finances-{projectId}`
- Backward compatibility with legacy key
- Warning log when using legacy storage

**Updated `lib/services/firestore_sync_service.dart`:**
- Project-scoped transaction storage
- New structure: `users/{userId}/projects/{projectId}/transactions/{transactionId}`
- Maintains backward compatibility with legacy structure

### 3. State Management

**Created `lib/providers/project_provider.dart`:**
- ChangeNotifier-based state management for projects
- Project CRUD operations
- Current project selection
- Global financial summary calculation
- Error handling with user-friendly messages

**Updated `lib/main.dart`:**
- Added ProjectProvider to MultiProvider
- Initialized ProjectService with FirestoreProjectSyncService

### 4. UI Components

**Created `lib/widgets/project_drawer.dart`:**
- Drawer widget with project list
- Global financial summary (all projects combined)
- Create project dialog
- Rename project dialog
- Delete project confirmation dialog
- Visual indication of selected project
- Responsive design for mobile and web

**Updated `lib/screens/home_screen.dart`:**
- Integration with ProjectProvider
- Automatic migration on first run
- Project-scoped transaction loading
- Global summary calculation
- Project switching support
- Updated app bar to show current project name
- Added drawer integration

### 5. Security

**Updated `firestore.rules`:**
- Added rules for projects collection
- Project CRUD permissions (users can only access their own)
- Nested transaction rules under projects
- Maintained legacy transaction rules for backward compatibility
- Validation for project data structure

### 6. Testing

**Created `test/models/project_test.dart`:**
- Project model creation tests
- JSON serialization/deserialization tests
- Soft-delete behavior tests
- copyWith functionality tests
- Equality tests

**Created `test/services/project_service_test.dart`:**
- Project CRUD operation tests
- Current project ID management tests
- Default project creation tests
- Data integrity tests
- Error handling tests

**Created `test/services/migration_service_test.dart`:**
- Migration execution tests
- Legacy data handling tests
- Backup and restore tests
- Migration status tests
- One-time execution verification

### 7. Documentation

**Updated `docs/ARCHITECTURE.md`:**
- Added Project model to project structure
- Updated data storage schema with project-scoped keys
- Documented Firestore structure for projects
- Added data migration section
- Updated service descriptions

**Updated `README.md`:**
- Added "Multiple Projects" feature description
- Updated usage guide with project management instructions
- Added data migration information
- Updated feature list with project capabilities

## Key Design Decisions

### 1. Local-First Architecture

Maintained the existing local-first approach:
- Projects stored in SharedPreferences with key `'projects'`
- Transactions stored per-project with key `'project-finances-{projectId}'`
- Cloud sync is optional and fails gracefully

### 2. Soft Delete

Projects use soft-delete pattern:
- `deletedAt` timestamp instead of hard deletion
- Preserves data for potential recovery
- Keeps audit trail
- Follows existing pattern from AppUser model

### 3. Default Project

Default project strategy:
- ID: `'default'`
- Name: `'Default'`
- Created automatically if no projects exist
- Legacy data migrated to this project

### 4. Project-Scoped Storage

Storage keys are project-scoped:
- Local: `'project-finances-{projectId}'`
- Cloud: `users/{userId}/projects/{projectId}/transactions/{transactionId}`
- Enables data isolation between projects
- Allows efficient loading of project-specific data

### 5. Migration Strategy

One-time automatic migration:
- Runs on first app launch after update
- Creates backup of legacy data
- Marks completion in SharedPreferences
- User notification on migration
- Safe rollback mechanism

## Data Flow

### Creating a Transaction

1. User selects project from drawer (or uses current)
2. User fills transaction form
3. Transaction saved to `StorageService` with current project ID
4. Local storage: `'project-finances-{projectId}'`
5. Cloud sync (if enabled): `users/{userId}/projects/{projectId}/transactions/{transactionId}`

### Switching Projects

1. User opens drawer
2. User taps different project
3. `ProjectProvider.selectProject()` called
4. Current project ID updated in SharedPreferences
5. `HomeScreen` refreshes transactions for new project
6. Global summary recalculated

### Global Summary

1. `ProjectProvider.getGlobalSummary()` iterates all projects
2. For each project, creates temporary StorageService
3. Loads transactions for that project
4. Calculates income/expenses
5. Aggregates across all projects
6. Returns combined summary

## Testing Coverage

- ✅ Project model serialization
- ✅ Project CRUD operations
- ✅ Data migration logic
- ✅ Default project creation
- ✅ Soft delete behavior
- ✅ Migration backup/restore

## Backward Compatibility

- ✅ Legacy transactions automatically migrated
- ✅ Backup created before migration
- ✅ Legacy storage key still supported during transition
- ✅ Firestore security rules maintain legacy structure

## Future Enhancements

Potential improvements for future iterations:

1. **Project Templates**: Pre-configured project types (exhibition, publication, etc.)
2. **Project Archiving**: Archive completed projects instead of deleting
3. **Project Sharing**: Share projects with collaborators
4. **Project Analytics**: Detailed insights per project
5. **Project Budgets**: Set and track budgets per project
6. **Project Tags**: Tag-based organization beyond projects
7. **Export by Project**: Export financial data per project
8. **Project Timeline**: Visualize project financial timeline

## Known Limitations

1. No undo for project deletion (data is soft-deleted but UI doesn't expose recovery)
2. Global summary calculation could be optimized with caching
3. No limit on number of projects (could impact performance with many projects)
4. Project names must be unique per user (not enforced)

## Security Considerations

- ✅ Firestore rules enforce user-level access control
- ✅ Projects isolated per user
- ✅ Transactions isolated per project per user
- ✅ No cross-user data access possible
- ✅ Soft delete maintains data audit trail

## Performance Considerations

- Project list loads all projects at once (acceptable for expected usage)
- Global summary calculated on-demand (could be cached)
- Transaction loading is per-project (efficient)
- Firestore batch operations used for efficiency

## Deployment Notes

No special deployment steps required:
- Migration runs automatically on client
- Firestore rules can be deployed separately
- No breaking changes to existing API
- Backward compatible with existing data

## References

- Issue: [Multiple projects support]
- Implementation PR: [Link to PR]
- Related Documentation:
  - `docs/ARCHITECTURE.md`
  - `README.md`
  - `test/services/migration_service_test.dart`
