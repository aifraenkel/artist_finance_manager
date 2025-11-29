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
