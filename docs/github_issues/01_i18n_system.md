# Title: Comprehensive Internationalization (i18n) System

## Labels
enhancement, i18n, architecture, high-priority

## Body

## Overview

Implement a comprehensive internationalization (i18n) system to support users worldwide with multiple languages, as mandated by `claude.md` sections 3, 5, and 13.

## Background

`claude.md` explicitly requires:
- "All user-facing text must be fully localizable"
- "**Zero hardcoded strings** in UI code"
- "Support multiple languages"
- "Dynamic language switching without app restart"

**Current State:** Application likely has hardcoded strings that prevent global adoption.

## Requirements

### 1. Localization Infrastructure

- [ ] Integrate Flutter's `intl` package or `flutter_localizations`
- [ ] Set up ARB (Application Resource Bundle) files for translations
- [ ] Create translation key system for all UI strings
- [ ] Support for plural forms and gendered text
- [ ] Date/time format localization
- [ ] Number format localization

### 2. Language Support

**Initial languages (Priority 1):**
- English (en)
- Spanish (es)
- French (fr)
- German (de)

**Future languages (Priority 2):**
- Portuguese (pt), Italian (it), Japanese (ja), Chinese (zh), Arabic (ar)

### 3. Technical Implementation

**Code Pattern (from claude.md):**

✅ **GOOD:**
```dart
Text(AppLocalizations.of(context).welcomeMessage)
```

❌ **BAD:**
```dart
Text('Welcome') // Never hardcode strings
```

**Requirements:**
- Create `AppLocalizations` class
- Generate localization delegates
- Support for context-free translations
- Fallback language support (default to English)

### 4. Right-to-Left (RTL) Support

- [ ] RTL text direction for Arabic, Hebrew, etc.
- [ ] Mirror UI layouts for RTL languages
- [ ] Test all screens in RTL mode

### 5. Dynamic Language Switching

- [ ] Language preference setting in user preferences
- [ ] Switch language without app restart
- [ ] Persist language choice across sessions
- [ ] Sync language preference across devices (when backend ready)

### 6. Developer Experience

- [ ] Automated checks for hardcoded strings in CI
- [ ] Translation key naming conventions
- [ ] Missing translation warnings
- [ ] Documentation for contributors

## Acceptance Criteria

- [ ] Zero hardcoded user-facing strings in code
- [ ] All UI text uses localization keys
- [ ] Users can switch language dynamically
- [ ] At least 4 languages supported initially
- [ ] RTL languages work correctly
- [ ] Date/time/number formats respect locale
- [ ] CI fails if hardcoded strings are introduced

## Related Issues

- #20 - Multi-currency support (needs locale-aware formatting)
- #19 - Dark mode (preferences system integration)

## Related Files

- `lib/` - All widget files need i18n
- `lib/l10n/` - New directory for ARB files
- `pubspec.yaml` - Add i18n dependencies
- `claude.md` - Sections 3, 5, 13

## Priority

**High** - Required for global scale as per `claude.md`
