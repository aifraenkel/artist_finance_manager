# Title: Cross-Platform UI Consistency Testing

## Labels
testing, cross-platform, quality-assurance, medium-priority

## Body

## Overview

Implement comprehensive cross-platform UI consistency testing to ensure the app behaves identically across Web, iOS, and Android platforms, as mandated by `claude.md` section 2.

## Background

`claude.md` section 2 requires:
- "The app **must** behave identically across Web (Desktop and Mobile browsers), iOS (iPhone and iPad), and Android (Phone and Tablet)"
- "Test all features on all three platforms"
- "Maintain consistent behavior across platforms"

**Current State:** Testing may be limited to a single platform, risking inconsistencies.

## Requirements

### 1. Visual Regression Testing

Automated visual testing to catch UI regressions:

- [ ] Screenshot comparison across platforms
- [ ] Pixel-perfect layout verification
- [ ] Detect unintended visual changes
- [ ] Support for different screen sizes and densities

**Tools to consider:**
- Percy (visual testing platform)
- Applitools (AI-powered visual testing)
- Custom golden file testing (Flutter)

### 2. Platform Coverage

**Required test platforms:**

**Web:**
- [ ] Desktop Chrome
- [ ] Desktop Safari
- [ ] Desktop Firefox
- [ ] Mobile Chrome (iOS)
- [ ] Mobile Safari (iOS)
- [ ] Mobile Chrome (Android)

**Mobile:**
- [ ] iOS Simulator (multiple devices: iPhone SE, iPhone 15, iPad)
- [ ] Android Emulator (multiple devices: Pixel 5, Pixel Tablet)
- [ ] Real devices (at least one iOS and one Android)

### 3. Responsive Layout Testing

- [ ] Test all screen sizes (phone, tablet, desktop)
- [ ] Portrait and landscape orientations
- [ ] Different aspect ratios
- [ ] Edge cases (very small/large screens)
- [ ] Text scaling (accessibility)

### 4. Platform-Adaptive Widget Testing

Test widgets that adapt to platform:

```dart
testWidgets('Button adapts to platform', (tester) async {
  // Test on Android
  tester.binding.platformOverride = TargetPlatform.android;
  await tester.pumpWidget(MyApp());
  expect(find.byType(MaterialButton), findsOneWidget);

  // Test on iOS
  tester.binding.platformOverride = TargetPlatform.iOS;
  await tester.pumpWidget(MyApp());
  expect(find.byType(CupertinoButton), findsOneWidget);
});
```

### 5. Manual Testing Checklist

Create platform-specific testing checklists:

**Checklist Template:**
```markdown
## Feature: Add Transaction

### Web (Desktop)
- [ ] Form displays correctly
- [ ] Keyboard navigation works
- [ ] Submit button responsive
- [ ] Validation messages show
- [ ] Transaction appears in list

### Web (Mobile)
- [ ] Touch targets are appropriate size
- [ ] Form is usable on small screen
- [ ] Virtual keyboard doesn't obscure inputs
- [ ] Scrolling works smoothly

### iOS
- [ ] iOS-specific styling applied
- [ ] Haptic feedback works
- [ ] Swipe gestures work
- [ ] Animations smooth (60 FPS)
- [ ] Safe area respected

### Android
- [ ] Material Design styling correct
- [ ] Back button behavior correct
- [ ] Notifications work
- [ ] Animations smooth
- [ ] Edge-to-edge display respected
```

### 6. Automated Cross-Platform Testing

**CI Pipeline Integration:**
- [ ] Run widget tests on all platforms
- [ ] Run integration tests on web
- [ ] Run integration tests on mobile simulators
- [ ] Visual regression testing on all platforms
- [ ] Performance testing across platforms

### 7. Platform-Specific Issues Tracking

- [ ] Document known platform-specific issues
- [ ] Track platform parity gaps
- [ ] Prioritize platform consistency fixes
- [ ] Regular platform parity reviews

## Acceptance Criteria

- [ ] Visual regression testing framework set up
- [ ] Tests run on all 3 major platforms (Web, iOS, Android)
- [ ] Responsive layout tests for all screen sizes
- [ ] Platform-adaptive widget tests
- [ ] Manual testing checklists for all features
- [ ] CI runs tests on multiple platforms
- [ ] Platform parity dashboard/report
- [ ] Documentation for platform testing process

## Implementation Strategy

### Phase 1: Foundation
1. Choose visual regression testing tool
2. Set up screenshot comparison infrastructure
3. Define baseline screenshots for all platforms

### Phase 2: Automated Testing
1. Add widget tests for platform-adaptive widgets
2. Set up golden file testing
3. Integrate visual regression tests into CI
4. Test responsive layouts

### Phase 3: Manual Testing Process
1. Create manual testing checklists
2. Define testing workflow before releases
3. Train team on platform testing
4. Document platform-specific quirks

### Phase 4: Monitoring & Improvement
1. Set up platform parity tracking
2. Regular platform testing reviews
3. Fix platform consistency issues
4. Update tests as app evolves

## Testing Matrix

| Feature | Web Desktop | Web Mobile | iOS | Android | Status |
|---------|-------------|------------|-----|---------|--------|
| Add Transaction | ✅ | ✅ | ✅ | ✅ | Pass |
| View Summary | ✅ | ✅ | ❌ | ✅ | iOS failing |
| Delete Transaction | ✅ | ✅ | ✅ | ❌ | Android failing |
| Authentication | 🔄 | 🔄 | 🔄 | 🔄 | In progress |

## Common Platform Issues to Test

### Web-Specific
- Canvas rendering (CanvasKit vs HTML)
- Browser-specific CSS quirks
- Keyboard shortcuts
- Right-click context menus
- PWA installation

### iOS-Specific
- Safe area insets
- Notch handling
- Home indicator
- iOS-specific gestures
- Haptic feedback

### Android-Specific
- Back button behavior
- Material Design compliance
- Status bar transparency
- Edge-to-edge display
- System navigation (gesture/buttons)

## Related Issues

- #21 - Real E2E tests for web
- #22 - Integration tests for web
- Relates to: Accessibility features (cross-platform a11y)

## Related Files

- `test/` - All test files
- `test/golden/` - Golden file screenshots (new)
- `.github/workflows/` - CI configuration
- `claude.md` - Section 2

## Priority

**Medium** - Important for quality, should be implemented before major releases

## Resources

- [Flutter Platform-Specific Code](https://docs.flutter.dev/development/platform-integration/platform-channels)
- [Percy Visual Testing](https://percy.io/)
- [Applitools](https://applitools.com/)
- [Flutter Golden Tests](https://api.flutter.dev/flutter/flutter_test/matchesGoldenFile.html)

## Testing Tools

**Visual Regression:**
- Percy
- Applitools
- Flutter Golden Tests
- Chromatic (for Storybook)

**Device Farms:**
- Firebase Test Lab (Android)
- AWS Device Farm (iOS + Android)
- BrowserStack (Web + Mobile)
- Sauce Labs (Web + Mobile)
