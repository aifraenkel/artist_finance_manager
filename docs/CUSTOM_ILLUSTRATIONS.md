# Custom Illustrations Guide for Financial Goal Wizard

This document describes where to place custom illustrations for the Financial Goal Wizard feature.

## Overview

The Financial Goal Wizard currently uses placeholder icons. To provide a better user experience, custom illustrations should be created and placed in the following locations:

## Required Illustrations

### 1. Dashboard Banner - No Goal State

**Location**: `lib/widgets/no_goal_banner.dart` (line ~23-31)

**Current Implementation**:
```dart
Container(
  width: 120,
  height: 120,
  decoration: BoxDecoration(
    color: AppColors.primary.withAlpha(50),
    borderRadius: BorderRadius.circular(60),
  ),
  child: Icon(
    Icons.track_changes,
    size: 60,
    color: AppColors.primary,
  ),
)
```

**Recommended**:
- Size: 120x120 pixels
- Format: SVG or PNG with transparency
- Theme: Goal setting, target, financial planning
- Style: Match app's design system (clean, modern, artist-friendly)
- Asset path: `assets/illustrations/no_goal_banner.svg` or `.png`

**How to Replace**:
```dart
Image.asset(
  'assets/illustrations/no_goal_banner.png',
  width: 120,
  height: 120,
)
```

### 2. Wizard Example Goals (Optional Enhancement)

**Location**: `lib/widgets/financial_goal_wizard.dart` (line ~324 in _buildExampleGoal)

**Current Implementation**: Uses `Icons.lightbulb_outline`

**Recommended**:
- Small icons for each example goal
- Size: 20x20 pixels
- Style: Line art or simple illustrations
- Could differentiate by goal type (savings, income, emergency fund, etc.)

## Asset Configuration

To use custom illustrations, add them to `pubspec.yaml`:

```yaml
flutter:
  assets:
    - assets/illustrations/no_goal_banner.png
    - assets/illustrations/goal_wizard_header.png
    # Add more as needed
```

## Design Guidelines

### Color Scheme
- Primary: `AppColors.primary` (#2563EB - Blue)
- Success: `AppColors.success` (Green)
- Accent: `AppColors.accent` (Orange/Amber)

### Style Recommendations
1. **Minimalist**: Clean lines, not too detailed
2. **Friendly**: Approachable for creative professionals
3. **Professional**: Maintain credibility for financial advice
4. **Consistent**: Match existing app design language

### Themes to Explore
- Target with arrow
- Growing plant/money tree
- Ascending graph/chart
- Calendar with checkmark
- Piggy bank (artist-themed)
- Musical instrument with dollar sign (for musicians)
- Paintbrush with coin (for visual artists)

## Implementation Checklist

- [ ] Create dashboard banner illustration (120x120)
- [ ] Export in appropriate format (SVG preferred, PNG acceptable)
- [ ] Add illustrations to `assets/illustrations/` directory
- [ ] Update `pubspec.yaml` to include assets
- [ ] Update `lib/widgets/no_goal_banner.dart` to use custom illustration
- [ ] Test on multiple devices and screen sizes
- [ ] Verify illustrations look good in both light and dark modes (if applicable)

## Future Enhancements (Phase 2)

### Wizard Step Headers
Consider adding illustrations for each wizard step:
1. **Step 1** (Goal Definition): Writing/notepad illustration
2. **Step 2** (Timeline): Calendar/clock illustration
3. **Step 3** (Confirmation): Checkmark/celebration illustration

### Goal Achievement States
For Phase 2 dashboard visualization:
- Progress bars with milestone icons
- Celebration illustration for achieved goals
- Motivational illustration for goals in progress

## Resources

### Design Tools
- Figma (recommended for vector illustrations)
- Adobe Illustrator
- Inkscape (free, open-source)

### Illustration Libraries (with appropriate licenses)
- undraw.co (free, customizable)
- Storyset by Freepik (free tier available)
- Humaaans (free, customizable characters)
- OpenPeeps (free, hand-drawn style)

## Notes

- Ensure all custom illustrations comply with licensing requirements
- Maintain high contrast for accessibility
- Test illustrations with colorblind simulation tools
- Keep file sizes optimized for web/mobile performance
- Consider animation for enhanced user experience (Flutter's `AnimatedContainer`, `Lottie`)
