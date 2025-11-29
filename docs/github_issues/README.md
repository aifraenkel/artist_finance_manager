# GitHub Issues for Artist Finance Manager

This directory contains issue descriptions for features identified from `claude.md` that are not yet tracked in GitHub issues.

## How to Create These Issues

### Option 1: Using GitHub Web Interface

1. Go to https://github.com/aifraenkel/artist_finance_manager/issues/new
2. Copy the title and body from each markdown file
3. Add the suggested labels
4. Create the issue

### Option 2: Using GitHub CLI (gh)

Run these commands from the repository root:

```bash
# New Issues
gh issue create --title "Comprehensive Internationalization (i18n) System" \
  --label "enhancement,i18n,architecture,high-priority" \
  --body-file /tmp/github_issues/01_i18n_system.md

gh issue create --title "Comprehensive Accessibility Features" \
  --label "enhancement,accessibility,a11y,high-priority" \
  --body-file /tmp/github_issues/02_accessibility_features.md

gh issue create --title "User Preferences System Architecture" \
  --label "enhancement,architecture,preferences,medium-priority" \
  --body-file /tmp/github_issues/03_preferences_system_architecture.md

gh issue create --title "State Management Migration (Provider/Riverpod)" \
  --label "enhancement,architecture,refactoring,medium-priority" \
  --body-file /tmp/github_issues/04_state_management_migration.md

gh issue create --title "Repository Pattern & Data Layer Abstraction" \
  --label "enhancement,architecture,backend,medium-priority" \
  --body-file /tmp/github_issues/05_repository_pattern_abstraction.md

gh issue create --title "Remote Configuration System" \
  --label "enhancement,infrastructure,low-priority" \
  --body-file /tmp/github_issues/06_remote_configuration_system.md

gh issue create --title "Cross-Platform UI Consistency Testing" \
  --label "testing,cross-platform,quality-assurance,medium-priority" \
  --body-file /tmp/github_issues/07_cross_platform_ui_testing.md

gh issue create --title "Deployment Smoke Test Automation" \
  --label "testing,ci-cd,deployment,low-priority" \
  --body-file /tmp/github_issues/08_deployment_smoke_tests.md
```

### Option 3: Bulk Create Script

```bash
#!/bin/bash
# Create all new issues at once

cd /tmp/github_issues

for file in 0*.md; do
  issue_number=$(echo $file | grep -o '^[0-9]*')
  echo "Creating issue from $file..."

  # Extract title from first line
  title=$(head -1 $file | sed 's/# Title: //')

  # Extract labels if present
  labels=$(grep "^## Labels" -A 1 $file | tail -1)

  # Extract body (skip title and labels)
  body=$(sed '1,/^## Body/d' $file)

  gh issue create --title "$title" --label "$labels" --body "$body"
done
```

## Update Existing Issues

For issues that need updates, copy the content from the update files and edit the existing issues on GitHub:

- **Issue #20** (Multi-currency support): Use `update_issue_20_multicurrency.md`
- **Issue #13** (Backend sync support): Use `update_issue_13_backend_sync.md`
- **Issue #16** (Multiple projects support): Use `update_issue_16_multiple_projects.md`
- **Issue #19** (Dark mode): Use `update_issue_19_dark_mode.md`

## Files in This Directory

### New Issues
1. `01_i18n_system.md` - Comprehensive Internationalization (i18n) System
2. `02_accessibility_features.md` - Comprehensive Accessibility Features
3. `03_preferences_system_architecture.md` - User Preferences System Architecture
4. `04_state_management_migration.md` - State Management Migration (Provider/Riverpod)
5. `05_repository_pattern_abstraction.md` - Repository Pattern & Data Layer Abstraction
6. `06_remote_configuration_system.md` - Remote Configuration System
7. `07_cross_platform_ui_testing.md` - Cross-Platform UI Consistency Testing
8. `08_deployment_smoke_tests.md` - Deployment Smoke Test Automation

### Updates to Existing Issues
- `update_issue_20_multicurrency.md` - Enhanced description for issue #20
- `update_issue_13_backend_sync.md` - Enhanced description for issue #13
- `update_issue_16_multiple_projects.md` - Enhanced description for issue #16
- `update_issue_19_dark_mode.md` - Enhanced description for issue #19

## Priority Summary

### High Priority
- Comprehensive Internationalization (i18n) System
- Comprehensive Accessibility Features

### Medium Priority
- User Preferences System Architecture
- State Management Migration (Provider/Riverpod)
- Repository Pattern & Data Layer Abstraction
- Cross-Platform UI Consistency Testing
- Multi-currency support (issue #20)
- Multiple projects support (issue #16)
- Backend sync support (issue #13)

### Low Priority
- Remote Configuration System
- Deployment Smoke Test Automation
- Dark mode (issue #19)

## Dependencies

Some issues depend on others:

```
User Preferences System Architecture
  ├── Blocks: i18n System (language preference)
  ├── Blocks: Multi-currency (#20) (currency preference)
  └── Blocks: Dark mode (#19) (theme preference)

Repository Pattern & Data Layer Abstraction
  ├── Blocks: Backend sync (#13) (repository interfaces)
  └── Blocks: Multiple projects (#16) (project repository)

State Management Migration
  └── Integrates with: User Preferences System

Backend Sync (#13)
  └── Depends on: Repository Pattern
```

## Source

All issues were extracted from the analysis of `claude.md` (from main branch) compared against existing GitHub issues as of 2025-11-29.
