# Update for Issue #19: Dark mode

## Current Description
"Implement dark mode theme support for better viewing experience in low-light conditions."

## Suggested Enhanced Description

---

## Overview

Implement comprehensive theme support (light, dark, and high-contrast modes) integrated with the user preferences system, as specified in `claude.md` sections 3 and 5.

## Background

`claude.md` requires:
- **Section 3:** "High Accessibility" including high contrast modes
- **Section 5:** Theme preferences should persist across devices, sync via preferences service, and update UI reactively

**Current State:** App likely uses default Material theme (light mode only).

## Requirements

### 1. Supported Themes

**Priority 1 (Initial Release):**
- [ ] Light mode (default)
- [ ] Dark mode
- [ ] System theme (follow OS setting)

**Priority 2 (Accessibility):**
- [ ] High contrast light mode
- [ ] High contrast dark mode

### 2. Theme Architecture

Integrate with User Preferences System (separate issue):

```dart
// Theme preference stored in preferences service
enum ThemeMode {
  light,
  dark,
  system,          // Follow OS setting
  highContrastLight,
  highContrastDark,
}

// User preference
await preferencesService.set('theme', ThemeMode.dark);

// Watch for changes (reactive UI)
preferencesService.watch<ThemeMode>('theme').listen((theme) {
  // Update app theme automatically
});
```

### 3. Material Design 3 Themes

**Light Theme:**
```dart
final lightTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,
  colorScheme: ColorScheme.fromSeed(
    seedColor: Colors.blue,
    brightness: Brightness.light,
  ),
  // ... additional customization
);
```

**Dark Theme:**
```dart
final darkTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  colorScheme: ColorScheme.fromSeed(
    seedColor: Colors.blue,
    brightness: Brightness.dark,
  ),
  // ... additional customization
);
```

**High Contrast Themes:**
```dart
final highContrastLightTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,
  colorScheme: const ColorScheme.highContrastLight(),
  // Ensure 7:1 contrast ratio (WCAG AAA)
);

final highContrastDarkTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  colorScheme: const ColorScheme.highContrastDark(),
  // Ensure 7:1 contrast ratio (WCAG AAA)
);
```

### 4. Theme Switcher UI

**Settings Screen:**
```
┌─────────────────────────────────┐
│ Settings                        │
├─────────────────────────────────┤
│                                 │
│ Appearance                      │
│                                 │
│ Theme                           │
│ ○ Light                         │
│ ● Dark                          │
│ ○ System (follows device)       │
│ ○ High Contrast Light           │
│ ○ High Contrast Dark            │
│                                 │
└─────────────────────────────────┘
```

**Quick toggle (optional):**
- Theme toggle button in app bar
- Switches between light/dark/system
- Smooth transition animation

### 5. Reactive Theme Updates

**No app restart required:**

```dart
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<ThemeMode>(
      stream: preferencesService.watch<ThemeMode>('theme'),
      builder: (context, snapshot) {
        final themeMode = snapshot.data ?? ThemeMode.system;

        return MaterialApp(
          theme: lightTheme,
          darkTheme: darkTheme,
          highContrastTheme: highContrastLightTheme,
          highContrastDarkTheme: highContrastDarkTheme,
          themeMode: _mapToMaterialThemeMode(themeMode),
          // ... other config
        );
      },
    );
  }
}
```

**When user changes theme:**
1. Save preference to PreferencesService
2. Preference stream emits new value
3. StreamBuilder rebuilds MaterialApp
4. UI updates with new theme (animated transition)
5. No manual refresh needed

### 6. Cross-Device Sync

**When backend sync is ready (#13):**
- [ ] Theme preference syncs across devices
- [ ] User sets dark mode on phone → tablet updates automatically
- [ ] Offline-first: local preference used immediately
- [ ] Syncs to cloud in background
- [ ] Conflict resolution: last-write-wins

### 7. Color Palette

**Ensure consistency:**

```dart
// Define semantic colors, not literal colors
class AppColors {
  // Surfaces
  static const surface = Color(0xFF...');
  static const surfaceVariant = Color(0xFF...');

  // Primary
  static const primary = Color(0xFF...');
  static const onPrimary = Color(0xFF...');

  // Semantic colors
  static const income = Colors.green;
  static const expense = Colors.red;
  static const balance = Colors.blue;

  // Status
  static const success = Colors.green;
  static const warning = Colors.orange;
  static const error = Colors.red;
}
```

**Both themes must:**
- Define all semantic colors
- Maintain consistent meaning (green = positive, red = negative)
- Pass accessibility contrast requirements

### 8. Accessibility Requirements

**Contrast Ratios (WCAG 2.1):**
- Regular themes: 4.5:1 minimum (WCAG AA)
- High contrast themes: 7:1 minimum (WCAG AAA)

**Testing:**
- [ ] Test all text on all backgrounds
- [ ] Test with color-blind simulators
- [ ] Test with screen readers (should announce theme)
- [ ] Verify no loss of information in any theme

### 9. Theme Preview

**Optional: Live preview before applying:**
```
┌─────────────────────────────────┐
│ Choose Theme                    │
├─────────────────────────────────┤
│ ┌─────────┐  ┌─────────┐       │
│ │ Light   │  │ Dark    │       │
│ │ Preview │  │ Preview │       │
│ └─────────┘  └─────────┘       │
└─────────────────────────────────┘
```

### 10. Persistence

**Local storage (immediate):**
- Save theme preference to SharedPreferences/Hive
- Load on app start
- Apply before first frame renders (no flash of wrong theme)

**Cloud storage (when backend ready):**
- Sync to Firestore/backend
- Cross-device synchronization

## Acceptance Criteria

- [ ] Light theme implemented
- [ ] Dark theme implemented
- [ ] System theme option (follows OS)
- [ ] High contrast light theme
- [ ] High contrast dark theme
- [ ] Theme switcher in settings
- [ ] Reactive UI updates (no restart)
- [ ] Theme preference persists across sessions
- [ ] Theme syncs across devices (when backend ready)
- [ ] All colors meet accessibility contrast requirements
- [ ] Smooth theme transition animation
- [ ] No flash of wrong theme on app start
- [ ] Comprehensive testing on all themes
- [ ] Documentation updated

## Implementation Strategy

### Phase 1: Theme Foundation (Week 1)
1. Define light and dark ThemeData
2. Set up theme switching mechanism
3. Integrate with MaterialApp
4. Test theme application

### Phase 2: Preferences Integration (Week 2)
1. Add theme preference to PreferencesService
2. Make theme reactive (StreamBuilder)
3. Save/load theme preference
4. Test reactive updates

### Phase 3: UI & Settings (Week 3)
1. Create theme switcher in settings
2. Add quick toggle (optional)
3. Implement theme transition animation
4. Test user experience

### Phase 4: High Contrast Themes (Week 4)
1. Define high contrast themes
2. Ensure WCAG AAA compliance (7:1 contrast)
3. Test with accessibility tools
4. Add to theme switcher

### Phase 5: Polish & Testing (Week 5)
1. Prevent flash of wrong theme on start
2. Test all screens in all themes
3. Fix any theme-specific issues
4. Cross-device sync (if backend ready)
5. Documentation

## Testing Strategy

### Automated Testing
```dart
testWidgets('Theme switches correctly', (tester) async {
  final preferencesService = MockPreferencesService();

  await tester.pumpWidget(MyApp(preferencesService: preferencesService));

  // Verify light theme
  expect(Theme.of(tester.element(find.byType(Scaffold))).brightness,
         Brightness.light);

  // Change to dark theme
  preferencesService.set('theme', ThemeMode.dark);
  await tester.pumpAndSettle();

  // Verify dark theme applied
  expect(Theme.of(tester.element(find.byType(Scaffold))).brightness,
         Brightness.dark);
});
```

### Manual Testing
- [ ] Test all screens in light mode
- [ ] Test all screens in dark mode
- [ ] Test all screens in high contrast modes
- [ ] Test theme switching (smooth transition)
- [ ] Test on all platforms (Web, iOS, Android)
- [ ] Test with screen readers
- [ ] Test color-blind accessibility

### Accessibility Testing
- [ ] Run automated accessibility audits
- [ ] Check contrast ratios with tools
- [ ] Test with color-blind simulators
- [ ] Verify screen reader compatibility

## Design Considerations

**Color consistency:**
- Income = Green in both themes
- Expense = Red in both themes
- Balance = Blue in both themes
- Ensure sufficient contrast in all themes

**Avoid hardcoded colors:**
```dart
// ✅ GOOD: Use theme colors
Container(color: Theme.of(context).colorScheme.surface)

// ❌ BAD: Hardcoded colors
Container(color: Colors.white)  // Breaks in dark mode
```

## Related Issues

- Depends on: User Preferences System Architecture
- Relates to: Accessibility Features (high contrast requirement)
- Relates to: #13 - Backend sync (sync theme preference)

## Related Files

- `lib/theme/` (new directory)
- `lib/theme/light_theme.dart` (new)
- `lib/theme/dark_theme.dart` (new)
- `lib/theme/high_contrast_themes.dart` (new)
- `lib/services/preferences_service.dart` (theme preference)
- `lib/main.dart` (theme application)
- `lib/screens/settings_screen.dart` (theme switcher)
- `claude.md` - Sections 3, 5

## Priority

**Medium** - Nice to have, improves user experience and accessibility

## Resources

- [Material Design 3 Theming](https://m3.material.io/styles/color/the-color-system/overview)
- [Flutter Theming](https://docs.flutter.dev/cookbook/design/themes)
- [WCAG Contrast Requirements](https://www.w3.org/WAI/WCAG21/Understanding/contrast-minimum.html)
- [Color Contrast Checker](https://webaim.org/resources/contrastchecker/)
