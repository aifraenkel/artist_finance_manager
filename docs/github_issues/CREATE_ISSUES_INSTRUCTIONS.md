# Create MVP GitHub Issues - Step by Step Instructions

Since the GitHub CLI requires authentication, here are the **easiest ways** to create these issues:

---

## Method 1: Copy-Paste into GitHub Web UI (Recommended)

### MVP Foundation Issues (Create These First)

#### Issue 1: Repository Pattern & Data Layer Abstraction

1. Go to: https://github.com/aifraenkel/artist_finance_manager/issues/new
2. **Title:** `Repository Pattern & Data Layer Abstraction`
3. **Labels:** `enhancement`, `architecture`, `backend`, `mvp-critical`
4. **Milestone:** `MVP`
5. **Body:** Copy from `docs/github_issues/05_repository_pattern_abstraction.md`
6. Click "Submit new issue"

---

#### Issue 2: User Preferences System Architecture

1. Go to: https://github.com/aifraenkel/artist_finance_manager/issues/new
2. **Title:** `User Preferences System Architecture`
3. **Labels:** `enhancement`, `architecture`, `preferences`, `mvp-critical`
4. **Milestone:** `MVP`
5. **Body:** Copy from `docs/github_issues/03_preferences_system_architecture.md`
6. Click "Submit new issue"

---

#### Issue 3: State Management Migration (Provider)

1. Go to: https://github.com/aifraenkel/artist_finance_manager/issues/new
2. **Title:** `State Management Migration (Provider)`
3. **Labels:** `enhancement`, `architecture`, `refactoring`, `mvp-critical`
4. **Milestone:** `MVP`
5. **Body:** Copy from `docs/github_issues/04_state_management_migration.md`
6. Click "Submit new issue"

---

#### Issue 4: Basic i18n Setup (English + Spanish)

1. Go to: https://github.com/aifraenkel/artist_finance_manager/issues/new
2. **Title:** `Basic i18n Setup (English + Spanish)`
3. **Labels:** `enhancement`, `i18n`, `mvp-polish`
4. **Milestone:** `MVP`
5. **Body:** Copy the text below:

```markdown
## Overview

Set up internationalization (i18n) infrastructure with English and Spanish support for MVP.

## Background

From `claude.md`: "All user-facing text must be fully localizable" and "Zero hardcoded strings in UI code"

For MVP, we'll set up the infrastructure and support 2 languages. Full i18n system (10+ languages, RTL support) is post-MVP.

## Requirements

### 1. i18n Infrastructure

- [ ] Integrate Flutter's `flutter_localizations` package
- [ ] Set up ARB (Application Resource Bundle) files
- [ ] Create `AppLocalizations` class
- [ ] Configure MaterialApp for localization

### 2. Language Support (MVP)

- [ ] English (en) - Complete
- [ ] Spanish (es) - Complete

**Post-MVP:** Add more languages based on user demand

### 3. Replace Hardcoded Strings

- [ ] Audit codebase for hardcoded strings
- [ ] Replace with localization keys
- [ ] Update all widgets to use `AppLocalizations`

### 4. Language Switcher

- [ ] Add language preference to preferences service
- [ ] Create language selector in settings
- [ ] Dynamic language switching (no restart required)

## Acceptance Criteria

- [ ] i18n infrastructure set up
- [ ] All UI strings use localization keys (no hardcoded strings)
- [ ] App works in English and Spanish
- [ ] User can switch language in settings
- [ ] Language preference persists across sessions
- [ ] Easy to add more languages post-MVP

## Implementation

**Week 8 of MVP timeline**

1. Set up Flutter localization packages
2. Create ARB files for English and Spanish
3. Replace hardcoded strings with keys
4. Add language switcher to settings
5. Test in both languages

## Related Issues

- Blocked by: User Preferences System Architecture (language preference)
- Full roadmap: See `docs/github_issues/01_i18n_system.md` for post-MVP expansion

## Priority

**MVP Polish** - Set up infrastructure now, expand languages post-MVP
```

6. Click "Submit new issue"

---

#### Issue 5: Basic Accessibility (WCAG AA Baseline)

1. Go to: https://github.com/aifraenkel/artist_finance_manager/issues/new
2. **Title:** `Basic Accessibility (WCAG AA Baseline)`
3. **Labels:** `enhancement`, `accessibility`, `a11y`, `mvp-polish`
4. **Milestone:** `MVP`
5. **Body:** Copy the text below:

```markdown
## Overview

Implement baseline accessibility features to meet WCAG 2.1 Level AA standards for MVP launch.

## Background

From `claude.md` Section 3: App must have "High Accessibility" for global adoption.

For MVP: WCAG AA baseline (4.5:1 contrast)
Post-MVP: Full WCAG AAA compliance (7:1 contrast)

## Requirements

### 1. Screen Reader Support

- [ ] Add semantic labels to all interactive widgets
- [ ] Ensure buttons, inputs, and actions are properly labeled
- [ ] Test with VoiceOver (iOS) and TalkBack (Android)
- [ ] Web: Test with screen readers (NVDA, JAWS)

### 2. Keyboard Navigation

- [ ] Full keyboard navigation (no mouse required)
- [ ] Logical tab order
- [ ] Visible focus indicators
- [ ] Escape key closes dialogs/modals

### 3. Visual Accessibility

- [ ] Color contrast ratios: 4.5:1 minimum (WCAG AA)
- [ ] Don't rely solely on color to convey information
- [ ] Readable fonts and appropriate sizes
- [ ] Test with color-blind simulators

### 4. Touch Accessibility

- [ ] Minimum touch target size: 44x44 points
- [ ] Adequate spacing between interactive elements
- [ ] No time-based interactions

## Acceptance Criteria

- [ ] WCAG 2.1 Level AA compliance
- [ ] Screen reader testing passes on iOS, Android, Web
- [ ] Full keyboard navigation works
- [ ] Color contrast ratios meet AA standards (4.5:1)
- [ ] Touch targets are appropriately sized
- [ ] Accessibility audit documentation

## Implementation

**Week 8 of MVP timeline**

1. Audit current accessibility issues
2. Add semantic labels to all widgets
3. Implement keyboard navigation
4. Fix color contrast issues
5. Test with screen readers and accessibility tools

## Testing

- [ ] Manual testing with VoiceOver
- [ ] Manual testing with TalkBack  
- [ ] Manual testing keyboard-only navigation
- [ ] Automated: Lighthouse accessibility audit (web)
- [ ] Color contrast checker tools

## Related Issues

- Integrates with: #19 - Dark mode (ensure high contrast in both themes)
- Full roadmap: See `docs/github_issues/02_accessibility_features.md` for WCAG AAA post-MVP

## Priority

**MVP Polish** - Baseline for launch, comprehensive improvements post-MVP
```

6. Click "Submit new issue"

---

### Update Existing Issues

#### Update Issue #13: Backend sync support

1. Go to: https://github.com/aifraenkel/artist_finance_manager/issues/13
2. Click "Edit" (pencil icon next to the title)
3. **Replace body with:** Content from `docs/github_issues/update_issue_13_backend_sync.md`
4. **Add label:** `mvp-critical`
5. **Add to milestone:** `MVP`
6. Click "Update comment"

---

#### Update Issue #16: Multiple projects support

1. Go to: https://github.com/aifraenkel/artist_finance_manager/issues/16
2. Click "Edit"
3. **Replace body with:** Content from `docs/github_issues/update_issue_16_multiple_projects.md`
4. **Add label:** `mvp-critical`
5. **Add to milestone:** `MVP`
6. Click "Update comment"

---

#### Update Issue #19: Dark mode

1. Go to: https://github.com/aifraenkel/artist_finance_manager/issues/19
2. Click "Edit"
3. **Replace body with:** Content from `docs/github_issues/update_issue_19_dark_mode.md`
4. **Add label:** `mvp-polish` (NOT mvp-critical, this is post-MVP)
5. **Add to milestone:** `Post-MVP v1.1`
6. Click "Update comment"

---

#### Update Issue #20: Multi-currency support

1. Go to: https://github.com/aifraenkel/artist_finance_manager/issues/20
2. Click "Edit"
3. **Replace body with:** Content from `docs/github_issues/update_issue_20_multicurrency.md`
4. **Add label:** `mvp-critical`
5. **Add to milestone:** `MVP`
6. Click "Update comment"

---

#### Update Issue #14: Export to CSV/PDF

1. Go to: https://github.com/aifraenkel/artist_finance_manager/issues/14
2. Click "Edit"
3. **Add label:** `mvp-polish`
4. **Add to milestone:** `MVP`
5. Click "Update comment"

---

## Method 2: Using GitHub CLI (If Authenticated)

If you have `gh` CLI installed and authenticated:

```bash
# Create milestone first
gh milestone create "MVP" --description "Minimum Viable Product with solid architecture"
gh milestone create "Post-MVP v1.1" --description "Post-launch enhancements"

# Create new issues
gh issue create --title "Repository Pattern & Data Layer Abstraction" \
  --label "enhancement,architecture,backend,mvp-critical" \
  --milestone "MVP" \
  --body-file docs/github_issues/05_repository_pattern_abstraction.md

gh issue create --title "User Preferences System Architecture" \
  --label "enhancement,architecture,preferences,mvp-critical" \
  --milestone "MVP" \
  --body-file docs/github_issues/03_preferences_system_architecture.md

gh issue create --title "State Management Migration (Provider)" \
  --label "enhancement,architecture,refactoring,mvp-critical" \
  --milestone "MVP" \
  --body-file docs/github_issues/04_state_management_migration.md

# Create basic i18n issue
cat > /tmp/basic_i18n.md << 'ISSUE_BODY'
[Copy the i18n body from above]
ISSUE_BODY

gh issue create --title "Basic i18n Setup (English + Spanish)" \
  --label "enhancement,i18n,mvp-polish" \
  --milestone "MVP" \
  --body-file /tmp/basic_i18n.md

# Create basic a11y issue
cat > /tmp/basic_a11y.md << 'ISSUE_BODY'
[Copy the a11y body from above]
ISSUE_BODY

gh issue create --title "Basic Accessibility (WCAG AA Baseline)" \
  --label "enhancement,accessibility,a11y,mvp-polish" \
  --milestone "MVP" \
  --body-file /tmp/basic_a11y.md

# Update existing issues (requires editing via web UI for body)
gh issue edit 13 --add-label "mvp-critical" --milestone "MVP"
gh issue edit 16 --add-label "mvp-critical" --milestone "MVP"
gh issue edit 19 --add-label "mvp-polish" --milestone "Post-MVP v1.1"
gh issue edit 20 --add-label "mvp-critical" --milestone "MVP"
gh issue edit 14 --add-label "mvp-polish" --milestone "MVP"
```

---

## Summary of Issues to Create

### New Issues (5 total):
1. ✅ Repository Pattern & Data Layer Abstraction (mvp-critical)
2. ✅ User Preferences System Architecture (mvp-critical)
3. ✅ State Management Migration (Provider) (mvp-critical)
4. ✅ Basic i18n Setup (English + Spanish) (mvp-polish)
5. ✅ Basic Accessibility (WCAG AA Baseline) (mvp-polish)

### Existing Issues to Update (5 total):
1. ✅ #13 - Backend sync support (add mvp-critical, update body)
2. ✅ #16 - Multiple projects support (add mvp-critical, update body)
3. ✅ #20 - Multi-currency support (add mvp-critical, update body)
4. ✅ #14 - Export to CSV/PDF (add mvp-polish)
5. ✅ #19 - Dark mode (add mvp-polish, mark as post-MVP)

---

## MVP Workflow

Once issues are created:

**Week 1-3: Foundation**
1. Repository Pattern (#new1)
2. Preferences System (#new2)
3. State Management (#new3)

**Week 4-7: Core Features**
4. Multiple Projects (#16)
5. Multi-Currency (#20)
6. Backend Sync (#13)

**Week 8: Polish**
7. Export (#14)
8. Basic i18n (#new4)
9. Basic Accessibility (#new5)

**Post-MVP:**
- Dark mode (#19)
- Charts (#15)
- Budget planning (#17)
- Receipt photos (#18)
- Full i18n & accessibility
