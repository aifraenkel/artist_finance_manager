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
