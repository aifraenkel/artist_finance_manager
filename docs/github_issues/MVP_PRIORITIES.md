# MVP Priorities: Create These Issues First

This is the prioritized subset of issues to create for a **valuable MVP with solid architecture**.

---

## 🔴 CRITICAL - Phase 1: Foundation (Weeks 1-3)

These provide the architectural foundation. Do these FIRST before any features.

### 1. Repository Pattern & Data Layer Abstraction
**Create from:** `docs/github_issues/05_repository_pattern_abstraction.md`

**Why first:**
- Prevents rewrite when adding backend sync
- Makes testing easy
- Blocks all other features

**Labels:** `enhancement`, `architecture`, `backend`, `mvp-critical`

**Command:**
```bash
gh issue create --title "Repository Pattern & Data Layer Abstraction" \
  --label "enhancement,architecture,backend,mvp-critical" \
  --milestone "MVP" \
  --body-file docs/github_issues/05_repository_pattern_abstraction.md
```

---

### 2. User Preferences System Architecture
**Create from:** `docs/github_issues/03_preferences_system_architecture.md`

**Why second:**
- Foundation for currency, theme, language
- Blocks multi-currency and dark mode
- Simple now, hard to retrofit later

**Labels:** `enhancement`, `architecture`, `preferences`, `mvp-critical`

**Command:**
```bash
gh issue create --title "User Preferences System Architecture" \
  --label "enhancement,architecture,preferences,mvp-critical" \
  --milestone "MVP" \
  --body-file docs/github_issues/03_preferences_system_architecture.md
```

---

### 3. State Management Migration (Provider)
**Create from:** `docs/github_issues/04_state_management_migration.md`

**Why third:**
- Needed for reactive preferences
- Needed for multi-project state
- Much harder to refactor later

**Labels:** `enhancement`, `architecture`, `refactoring`, `mvp-critical`

**Command:**
```bash
gh issue create --title "State Management Migration (Provider)" \
  --label "enhancement,architecture,refactoring,mvp-critical" \
  --milestone "MVP" \
  --body-file docs/github_issues/04_state_management_migration.md
```

---

## 🔴 CRITICAL - Phase 2: MVP Features (Weeks 4-7)

Now build features on top of solid foundation. Update existing issues with enhanced descriptions.

### 4. Multiple Projects Support (Issue #16)
**Update from:** `docs/github_issues/update_issue_16_multiple_projects.md`

**Why critical:**
- Artists work on multiple projects
- Core differentiator
- Easy to build with repository pattern

**Action:**
1. Open issue #16 on GitHub
2. Edit description
3. Replace with content from `update_issue_16_multiple_projects.md`
4. Add label: `mvp-critical`
5. Add to milestone: `MVP`

---

### 5. Multi-Currency Support (Issue #20)
**Update from:** `docs/github_issues/update_issue_20_multicurrency.md`

**Why critical:**
- Essential for international artists
- Differentiator
- Easy with preferences system

**Action:**
1. Open issue #20 on GitHub
2. Edit description
3. Replace with content from `update_issue_20_multicurrency.md`
4. Add label: `mvp-critical`
5. Add to milestone: `MVP`

---

### 6. Backend Sync Support (Issue #13)
**Update from:** `docs/github_issues/update_issue_13_backend_sync.md`

**Why critical:**
- Cross-device usage essential
- Easy with repository pattern
- Offline-first built-in

**Action:**
1. Open issue #13 on GitHub
2. Edit description
3. Replace with content from `update_issue_13_backend_sync.md`
4. Add label: `mvp-critical`
5. Add to milestone: `MVP`

---

## 🟡 HIGH - Phase 3: MVP Polish (Week 8)

Quick wins that complete the MVP.

### 7. Export to CSV/PDF (Issue #14)
**Existing issue, just add labels**

**Why high:**
- Artists need for taxes
- Simple, high value
- Quick to implement

**Action:**
1. Add label: `mvp-critical`
2. Add to milestone: `MVP`

---

### 8. Basic i18n (English + Spanish)
**Create simplified version from:** `docs/github_issues/01_i18n_system.md`

**Why include (simplified):**
- Set up infrastructure for future
- English + Spanish covers large market
- Easy to add more languages later

**Scope:**
- Infrastructure setup only
- English (complete)
- Spanish (complete)
- NOT: Full 10-language support, RTL, etc.

**Create new simplified issue:**
```bash
gh issue create --title "Basic i18n Setup (English + Spanish)" \
  --label "enhancement,i18n,mvp-polish" \
  --milestone "MVP" \
  --body "Set up i18n infrastructure with English and Spanish support. See full i18n roadmap in docs/github_issues/01_i18n_system.md for post-MVP expansion."
```

---

### 9. Basic Accessibility (WCAG AA Baseline)
**Create simplified version from:** `docs/github_issues/02_accessibility_features.md`

**Why include (simplified):**
- Need baseline a11y for launch
- Legal compliance
- Can improve to AAA post-MVP

**Scope:**
- Screen reader labels
- Keyboard navigation
- Color contrast (WCAG AA: 4.5:1)
- NOT: WCAG AAA, full automation, etc.

**Create new simplified issue:**
```bash
gh issue create --title "Basic Accessibility (WCAG AA Baseline)" \
  --label "enhancement,accessibility,mvp-polish" \
  --milestone "MVP" \
  --body "Implement baseline accessibility: screen reader support, keyboard navigation, WCAG AA contrast. See full a11y roadmap in docs/github_issues/02_accessibility_features.md for post-MVP improvements."
```

---

## 🚫 NOT in MVP - Create Post-Launch

These are valuable but NOT needed for MVP. Create after launch.

### Post-MVP v1.1
- Charts and Analytics (Issue #15)
- Dark Mode (Issue #19)
- Budget Planning (Issue #17)
- Receipt Photos (Issue #18)
- Full i18n System (all languages, RTL)
- Comprehensive Accessibility (WCAG AAA)

### Post-MVP v1.2
- Cross-Platform UI Consistency Testing
- Remote Configuration System
- Deployment Smoke Test Automation

---

## 📋 Quick Command Reference

### Create All MVP Foundation Issues (Phase 1):

```bash
# Create milestone first
gh milestone create "MVP" --description "Minimum Viable Product with solid architecture"

# Foundation issues
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

# MVP Polish issues
gh issue create --title "Basic i18n Setup (English + Spanish)" \
  --label "enhancement,i18n,mvp-polish" \
  --milestone "MVP" \
  --body "Set up i18n infrastructure with English and Spanish support. Infrastructure allows easy addition of more languages post-MVP."

gh issue create --title "Basic Accessibility (WCAG AA Baseline)" \
  --label "enhancement,accessibility,mvp-polish" \
  --milestone "MVP" \
  --body "Implement baseline accessibility: screen reader support, keyboard navigation, WCAG AA color contrast (4.5:1)."
```

### Update Existing Issues (Phase 2):

Manually update these on GitHub:
1. Issue #16 - Add `mvp-critical` label, add to `MVP` milestone, update description
2. Issue #20 - Add `mvp-critical` label, add to `MVP` milestone, update description
3. Issue #13 - Add `mvp-critical` label, add to `MVP` milestone, update description
4. Issue #14 - Add `mvp-critical` label, add to `MVP` milestone

---

## 🎯 MVP Definition

**Core Value:**
- ✅ Track income/expenses across multiple projects
- ✅ Multi-currency support
- ✅ Cross-device sync
- ✅ Export for taxes
- ✅ Works in English and Spanish
- ✅ Basic accessibility

**Technical Foundation:**
- ✅ Repository pattern (scalable data layer)
- ✅ Preferences system (easy to add settings)
- ✅ State management (reactive, testable)
- ✅ Backend on GCP
- ✅ Offline-first architecture
- ✅ Ready to scale to millions

**Timeline:** ~8 weeks

**Result:** Production-ready app that scales without rewrites

---

## 🏆 Why This Order

**Foundation First (Weeks 1-3):**
- Repository pattern prevents massive refactor later
- Preferences system makes features easy
- State management required for reactivity

**Features Second (Weeks 4-7):**
- With foundation in place, features are easy
- Each feature just adds a repository
- Clean, testable, scalable

**Polish Last (Week 8):**
- Quick wins to complete MVP
- Set up infrastructure for post-MVP expansion

**Result:**
- 8 weeks to valuable MVP
- Clean codebase
- No technical debt
- Ready to scale

---

## 📈 Success Metrics

**By End of Week 3:**
- ✅ Repository pattern working for transactions
- ✅ Preferences service implemented
- ✅ App uses Provider for state

**By End of Week 7:**
- ✅ Multi-project tracking working
- ✅ Multi-currency conversions working
- ✅ Backend deployed, data syncs across devices

**By End of Week 8:**
- ✅ Export to CSV working
- ✅ App works in English and Spanish
- ✅ Basic accessibility implemented
- ✅ First users onboarded

**Technical Quality:**
- ✅ All features have tests
- ✅ CI/CD passing
- ✅ Documentation up to date
- ✅ No hardcoded coupling
- ✅ Ready to add more features easily
