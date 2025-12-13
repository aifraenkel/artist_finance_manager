# Financial Goal Wizard - Phase 1 Implementation

This document provides an overview of the Financial Goal Wizard feature implemented in Phase 1.

## Overview

The Financial Goal Wizard transforms the budget planning feature into a first-class citizen by providing a guided, wizard-based approach for users to set meaningful financial goals. Users can describe their goals in their own words, set a due date, and choose how often they want progress updates.

## Features Implemented

### 1. Financial Goal Wizard (3-Step Process)

A full-screen modal wizard that guides users through setting up their financial goal:

**Step 1: Goal Definition**
- Text area for describing the financial goal (max 2,000 characters)
- Character counter showing remaining characters
- Inspiration section with 5 example goals for different creative professionals
- Validation to ensure goals meet requirements
- "Next" button to proceed (enabled only when valid)

**Step 2: Timeline & Notifications**
- Date picker for selecting goal due date
- Email cadence selector with options:
  - Daily
  - Weekly
  - Every two weeks
  - Monthly
  - Never (dashboard only)
- Date validation (must be future date)
- "Next" button to proceed

**Step 3: Confirmation**
- Display goal summary including:
  - Goal text
  - Due date
  - Email update frequency
- Automatic save to Firebase upon entering this step
- Call to OpenAI API (`gpt-4o`) to generate acknowledgment message
- Display AI-generated acknowledgment with loading spinner
- Error handling with fallback messages
- "Close" button to exit wizard

### 2. First-Time User Experience

- Automatic goal check when app opens
- Wizard appears automatically if user has no financial goal set
- "Skip for now" button available to dismiss
- Skipped state tracked to prevent repeated auto-showing
- Can be triggered manually from dashboard banner

### 3. Analytics Dashboard Integration

**No Goal Banner**
- Displayed when user has not set a financial goal
- Custom illustration placeholder (currently using icon)
- Localized caption inviting user to set a goal
- CTA button to open the wizard
- Appears both when dashboard is empty and when it has data

### 4. Data Model

Financial goals are stored in Firestore with the following structure:

```
users/{userId}/financialGoal/current
{
  "goal": String,           // User's goal description (max 2000 chars)
  "dueDate": Timestamp,     // Target date
  "emailCadence": String,   // "daily" | "weekly" | "biweekly" | "monthly" | "never"
  "createdAt": Timestamp,
  "updatedAt": Timestamp
}
```

### 5. Localization

- Full English and Spanish translations
- All wizard text, buttons, examples, and error messages are localized
- No hardcoded strings
- Banner captions localized

### 6. Deprecations

- Removed budget goal setup from ProfileScreen
- Removed OpenAI API key input from ProfileScreen
- Kept backend OpenAI integration (uses stored key from UserPreferences)
- Old budget goal analysis kept in dashboard for backward compatibility

## Technical Implementation

### New Files Created

**Models**
- `lib/models/financial_goal.dart` - FinancialGoal model with EmailCadence enum

**Services**
- `lib/services/financial_goal_service.dart` - Firebase CRUD operations
- Updated `lib/services/openai_service.dart` - Added gpt-4o support and acknowledgeGoal method
- Updated `lib/services/user_preferences.dart` - Added hasSkippedGoalWizard tracking

**Widgets**
- `lib/widgets/financial_goal_wizard.dart` - Main wizard implementation
- `lib/widgets/no_goal_banner.dart` - Dashboard banner component

**Prompts**
- `lib/prompts/goal_acknowledgment.md` - OpenAI prompt template

**Tests**
- `test/models/financial_goal_test.dart` - Model unit tests
- `test/services/financial_goal_service_test.dart` - Service unit tests

**Documentation**
- `docs/CUSTOM_ILLUSTRATIONS.md` - Custom illustrations guide

### Key Technical Decisions

1. **OpenAI Model**: Using `gpt-4o` instead of `gpt-3.5-turbo` for better quality responses

2. **Retry Logic**: Implemented exponential backoff for OpenAI API calls
   - Max retries: 3
   - Initial delay: 1 second
   - Exponential backoff on rate limits and network errors

3. **Firebase Structure**: Single document per user at `users/{userId}/financialGoal/current`
   - Allows for easy future extension to multiple goals
   - Clean separation from other user data

4. **State Management**: Uses Provider for auth state, local state for wizard flow

5. **Validation**: 
   - Client-side validation for character limits and date requirements
   - Server-side validation implicit in Firestore security rules

## Usage

### For Users

1. **First Time**: Wizard appears automatically after login
2. **From Dashboard**: Click "Set Your Goal" button in banner
3. **Skip**: Click "Skip for now" - can set goal later from dashboard

### For Developers

**Opening the Wizard Programmatically**:
```dart
Navigator.of(context).push(
  MaterialPageRoute(
    builder: (context) => FinancialGoalWizard(
      userId: user.uid,
      openAIApiKey: apiKey,
      onGoalSaved: () {
        // Callback when goal is saved
      },
      onSkipped: () {
        // Callback when user skips
      },
    ),
    fullscreenDialog: true,
  ),
);
```

**Checking if User Has Goal**:
```dart
final goalService = FinancialGoalService();
final hasGoal = await goalService.hasGoal(userId);
```

**Getting User's Goal**:
```dart
final goal = await goalService.getGoal(userId);
if (goal != null) {
  // Use goal data
}
```

## Testing

### Unit Tests
- ✅ FinancialGoal model tests (serialization, validation)
- ✅ FinancialGoalService tests (CRUD operations)
- Uses `fake_cloud_firestore` for Firestore mocking

### Integration Tests
- Will run in CI/CD pipeline
- Tests complete wizard flow
- Tests first-time user experience

### Manual Testing Checklist
- [ ] Wizard opens on first launch for new users
- [ ] Skip button works and prevents auto-showing
- [ ] Goal saves to Firebase correctly
- [ ] OpenAI acknowledgment generates properly
- [ ] Banner shows when no goal set
- [ ] Banner CTA opens wizard
- [ ] All localizations display correctly
- [ ] Character counter works accurately
- [ ] Date picker only allows future dates
- [ ] All email cadence options work

## Known Limitations & Future Work

### Phase 1 Limitations
1. **OpenAI API Key**: Currently uses stored key from UserPreferences
   - TODO: Create backend function to use shared `.env` key
   
2. **Email Delivery**: Email cadence selection implemented but emails not sent
   - Requires Phase 2 backend scheduler

3. **Goal Management**: No edit or delete functionality
   - Will be added in Phase 2

4. **Custom Illustrations**: Using placeholder icons
   - See `docs/CUSTOM_ILLUSTRATIONS.md` for adding custom art

### Future Enhancements (Phase 2 & 3)

**Phase 2: Goal Tracking & Visualization**
- Dashboard goal status widget
- Progress visualization (charts, progress bars)
- AI-powered progress summaries
- Goal achievement celebrations

**Phase 3: Email Notifications**
- Backend scheduler for email delivery
- Personalized progress reports based on cadence
- Goal milestone notifications

**Additional Enhancements**
- Multiple goals per user
- Goal templates for common scenarios
- Sharing goals with collaborators
- Goal history and analytics

## Dependencies

### Flutter Packages
- `cloud_firestore` - Firebase database
- `firebase_core` - Firebase initialization
- `intl` - Internationalization and date formatting
- `provider` - State management
- `http` - OpenAI API calls

### Development Dependencies
- `flutter_test` - Unit testing
- `fake_cloud_firestore` - Firestore mocking

## Configuration

### Firestore Security Rules

Add to `firestore.rules`:
```javascript
match /users/{userId}/financialGoal/{document} {
  allow read, write: if request.auth != null && request.auth.uid == userId;
}
```

### Assets

Add to `pubspec.yaml`:
```yaml
flutter:
  assets:
    - lib/prompts/goal_acknowledgment.md
```

## Troubleshooting

### Common Issues

**Wizard Not Appearing**
- Check that user is authenticated
- Verify no goal exists in Firebase
- Ensure `hasSkippedGoalWizard` is not set

**OpenAI Errors**
- Verify API key is set in UserPreferences
- Check network connectivity
- Review retry logic logs
- Validate prompt template is loaded correctly

**Character Counter Off**
- Ensure maxLength is set to 2000
- Check for Unicode character handling

**Date Picker Issues**
- Verify minimum date is set to today
- Check for timezone handling

## Contributing

When adding features:
1. Follow existing code structure
2. Add comprehensive tests
3. Update localizations (English & Spanish minimum)
4. Document in relevant README
5. Follow SOLID principles

## Support

For issues or questions:
1. Check this README
2. Review existing tests for examples
3. Check GitHub issues
4. Create new issue with detailed description

## License

This feature is part of the Artist Finance Manager project.
See LICENSE file in repository root for details.
