# Update for Issue #16: Multiple projects support

## Current Description
"Enable artists to manage finances for multiple art projects separately with the ability to switch between projects. The artist should be able to find am overview as a summary on finances for all projects, charts for all projects if charts were already implemented, highlight projects which are "in red" or need some care, additionally to the charts and analysis data in the project view."

## Suggested Enhanced Description

---

## Overview

Enable artists to manage finances for multiple art projects separately with project-based organization, cross-project analytics, and feature modularization as outlined in `claude.md` section 12.

## Background

`claude.md` section 12 describes feature modularization:
- `features/projects/` module
- `features/transactions/` module
- `features/analytics/` module
- Shared core module for common code
- Clean feature boundaries

Artists often work on multiple projects simultaneously (book, podcast, concert tour, art exhibition) and need to:
- Track finances separately per project
- Get overview across all projects
- Identify projects needing attention
- Analyze trends per project and globally

## Requirements

### 1. Project Data Model

```dart
class Project {
  final String id;  // UUID
  final String name;
  final String description;
  final ProjectStatus status;
  final DateTime createdAt;
  final DateTime? completedAt;
  final String? color;  // For visual identification
  final String? icon;   // Optional icon

  // Financial overview (computed)
  final int totalIncomeInCents;
  final int totalExpensesInCents;
  final int balanceInCents;

  // Metadata
  final DateTime updatedAt;
  final bool archived;
}

enum ProjectStatus {
  planning,      // Not started yet
  active,        // Currently working on
  completed,     // Finished
  onHold,        // Paused
  cancelled,     // Abandoned
}
```

### 2. Project-Transaction Relationship

**Update Transaction model:**
```dart
class Transaction {
  final String id;
  final String projectId;  // NEW: Link to project
  final int amountInCents;
  final String description;
  final TransactionType type;
  final String category;
  final DateTime createdAt;
  // ... other fields
}
```

**Requirements:**
- [ ] Every transaction belongs to exactly one project
- [ ] Deleting a project: choose to delete or archive transactions
- [ ] Moving transactions between projects
- [ ] Filter transactions by project

### 3. Project Switcher UI

**Navigation:**
- [ ] Project dropdown/selector in app bar
- [ ] Currently active project always visible
- [ ] Quick switch between recent projects
- [ ] "All Projects" view option
- [ ] Create new project button

**Example UI:**
```
┌─────────────────────────────────────┐
│ 📚 Book Project ▼          👤 Menu │
├─────────────────────────────────────┤
│  Recent Projects:                   │
│  📚 Book Project (Active)           │
│  🎙️ Podcast Series                  │
│  🎨 Gallery Exhibition              │
│  ➕ Create New Project              │
│  📊 All Projects Overview           │
└─────────────────────────────────────┘
```

### 4. All Projects Overview

**Summary Dashboard:**
- [ ] List all projects with key metrics
- [ ] Total income, expenses, balance per project
- [ ] Visual indicators (color-coded by status)
- [ ] Highlight projects "in the red" (negative balance)
- [ ] Sort by: status, balance, recent activity
- [ ] Quick actions: view, edit, archive

**Example Layout:**
```
All Projects Overview
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📚 Book Project                    ✅ Active
   Income: $5,000   Expenses: $3,000   Balance: $2,000

🎙️ Podcast Series                 ⚠️ In Red
   Income: $1,000   Expenses: $2,500   Balance: -$1,500

🎨 Gallery Exhibition              🔵 Planning
   Income: $0       Expenses: $500     Balance: -$500

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Total Across All Projects:
   Income: $6,000   Expenses: $6,000   Balance: $0
```

### 5. Project Alerts & Highlights

**Automatic highlighting:**
- [ ] 🔴 Projects with negative balance (in red)
- [ ] ⚠️ Projects over budget (if budget feature implemented)
- [ ] 📉 Projects with declining income trend
- [ ] ⏰ Projects with no activity in 30+ days
- [ ] ✅ Projects recently completed

### 6. Cross-Project Analytics

**If charts/analytics already implemented (#15):**
- [ ] Income/expense trends across all projects
- [ ] Comparison between projects
- [ ] Most profitable projects
- [ ] Most expensive projects
- [ ] Project performance over time
- [ ] Category breakdown across projects

### 7. Feature Modularization (Architecture)

Organize code into feature modules as per `claude.md` section 12:

```
lib/
├── features/
│   ├── projects/
│   │   ├── models/
│   │   │   └── project.dart
│   │   ├── repositories/
│   │   │   └── project_repository.dart
│   │   ├── services/
│   │   │   └── project_service.dart
│   │   ├── providers/
│   │   │   └── project_provider.dart
│   │   ├── screens/
│   │   │   ├── project_list_screen.dart
│   │   │   ├── project_detail_screen.dart
│   │   │   └── create_project_screen.dart
│   │   └── widgets/
│   │       ├── project_card.dart
│   │       └── project_selector.dart
│   │
│   ├── transactions/
│   │   ├── models/
│   │   ├── repositories/
│   │   ├── services/
│   │   ├── providers/
│   │   ├── screens/
│   │   └── widgets/
│   │
│   ├── analytics/  (if #15 implemented)
│   │   └── ...
│   │
│   └── core/  (shared code)
│       ├── models/
│       ├── services/
│       ├── widgets/
│       └── utils/
```

**Benefits:**
- Clear feature boundaries
- Easy to test in isolation
- Can be developed independently
- Easier to maintain and scale

### 8. Project Repository Pattern

```dart
abstract class ProjectRepository {
  Future<void> save(Project project);
  Future<Project?> findById(String id);
  Future<List<Project>> findAll();
  Future<List<Project>> findActive();
  Future<void> archive(String id);
  Future<void> delete(String id);
  Stream<List<Project>> watchAll();
}
```

### 9. Default Project

**For users who don't want multiple projects:**
- [ ] Automatically create "Default Project" on first launch
- [ ] All transactions go to default project if user doesn't switch
- [ ] Option to hide project selector (single-project mode)
- [ ] Can upgrade to multi-project later

## Acceptance Criteria

- [ ] Project data model implemented
- [ ] Transactions linked to projects
- [ ] Project repository and service layer
- [ ] Project switcher in UI
- [ ] Create/edit/delete/archive projects
- [ ] All Projects overview screen
- [ ] Summary shows all projects
- [ ] Highlight projects in red (negative balance)
- [ ] Filter transactions by project
- [ ] Default project for simple use case
- [ ] Feature modularization implemented
- [ ] Cross-project analytics (if #15 done)
- [ ] Backend sync for projects (if #13 done)
- [ ] Comprehensive tests
- [ ] Documentation updated

## Implementation Strategy

### Phase 1: Data Model & Repository (Week 1)
1. Create Project model
2. Update Transaction model (add projectId)
3. Create ProjectRepository
4. Create ProjectService
5. Add database migration

### Phase 2: Basic Project Management (Week 2)
1. Create project screens (list, detail, create/edit)
2. Implement project CRUD operations
3. Add project selector UI
4. Create default project on first launch

### Phase 3: Project-Transaction Integration (Week 3)
1. Link transactions to projects
2. Update transaction UI (show project)
3. Filter transactions by project
4. Update summary calculations per project

### Phase 4: All Projects Overview (Week 4)
1. Create all projects overview screen
2. Calculate totals per project
3. Highlight projects in red
4. Add project alerts
5. Cross-project summary

### Phase 5: Feature Modularization (Week 5)
1. Reorganize code into feature modules
2. Move projects code to features/projects/
3. Move transactions code to features/transactions/
4. Create shared core module
5. Update imports and dependencies

### Phase 6: Analytics Integration (Week 6, if #15 done)
1. Cross-project analytics
2. Project comparison charts
3. Project performance trends

## Testing Strategy

- [ ] Unit tests for Project model and repository
- [ ] Unit tests for ProjectService
- [ ] Widget tests for project screens
- [ ] Integration tests for project CRUD
- [ ] Test transaction-project relationship
- [ ] Test default project creation
- [ ] Test cross-project calculations

## User Stories

1. **As an artist**, I want to track finances for each project separately, so I can see which projects are profitable.

2. **As an artist**, I want to see all my projects in one overview, so I can quickly assess my overall financial situation.

3. **As an artist**, I want to be alerted when a project is losing money, so I can take corrective action.

4. **As an artist**, I want to compare financial performance across projects, so I can make informed decisions about future projects.

5. **As a simple user**, I want to use the app without thinking about projects, so I can just track my finances easily.

## Related Issues

- Depends on: Repository Pattern & Data Layer Abstraction
- Depends on: State Management Migration (project state)
- Integrates with: #15 - Charts and analytics (project analytics)
- Integrates with: #13 - Backend sync (sync projects)
- Integrates with: #17 - Budget planning (project budgets)

## Related Files

- `lib/features/projects/` (new feature module)
- `lib/features/transactions/` (refactor into feature module)
- `lib/features/core/` (new shared code)
- `lib/models/transaction.dart` (add projectId)
- `claude.md` - Section 12

## Priority

**Medium** - Valuable for professional artists, but single project works initially

## Migration Strategy

**For existing users:**
1. Create "Default Project" automatically
2. Assign all existing transactions to default project
3. User can create additional projects as needed
4. No disruption to existing workflows
