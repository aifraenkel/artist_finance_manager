# Multi-Currency Support Implementation Summary

## Overview

This document provides a comprehensive summary of the multi-currency and language support implementation for the Art Finance Hub application.

## What Was Implemented

### 1. User Preferences Model
**File:** `lib/models/user_preferences.dart`

Created enums and model for user preferences:
- `AppLanguage` enum: English, Spanish, Catalan
- `AppCurrency` enum: EUR (€), USD ($)
- `UserPreferencesModel`: Stores user preferences with userId, language, currency, updatedAt, and optional conversionRate

### 2. Preferences Service
**File:** `lib/services/preferences_service.dart`

Service for managing preferences in Firestore:
- `getPreferences(userId)`: Retrieves preferences or returns defaults
- `savePreferences(preferences)`: Saves to Firestore
- `updateLanguage(userId, language)`: Updates language only
- `updateCurrency(userId, currency, conversionRate)`: Updates currency with rate
- `initializeDefaultPreferences(userId)`: Creates defaults for new users
- `migrateUserPreferences(userId)`: Ensures existing users have preferences

### 3. Currency Conversion Service
**File:** `lib/services/currency_conversion_service.dart`

Service for fetching exchange rates from Frankfurter API:
- `getEurToUsdRate()`: Fetches current EUR→USD rate
- `getUsdToEurRate()`: Fetches current USD→EUR rate
- `convertEurToUsd(amount, rate)`: Converts with optional rate
- `convertUsdToEur(amount, rate)`: Converts with optional rate
- `convertCurrency(amount, from, to, rate)`: Generic conversion

### 4. Firestore Security Rules
**File:** `firestore.rules`

Added rules for preferences subcollection:
```javascript
match /users/{userId}/preferences/{preferencesId} {
  allow read, write: if isOwner(userId);
}
```

### 5. Updated Transaction Model
**File:** `lib/models/transaction.dart`

Added optional currency field:
```dart
final String? currency; // 'EUR' or 'USD'
```

### 6. Updated Export Service
**File:** `lib/services/export_service.dart`

CSV export now includes Currency column:
```csv
Project name,Type,Category,Description,Amount,Currency,Datetime
```

### 7. Profile Screen UI
**File:** `lib/screens/profile/profile_screen.dart`

Added preferences section with:
- Language dropdown (English, Spanish, Catalan)
- Currency dropdown (€ Euro, $ US Dollar)
- Currency change confirmation dialog
- Conversion rate fetching and storage

### 8. Auth Service Integration
**File:** `lib/services/auth_service.dart`

- New users: Initialize default preferences on registration
- Existing users: Migrate preferences on login
- Preferences migration is idempotent and non-blocking

### 9. UI Components Update

**SummaryCards** (`lib/widgets/summary_cards.dart`):
- Added `currencySymbol` parameter (default: '€')
- Displays user's preferred currency symbol

**TransactionList** (`lib/widgets/transaction_list.dart`):
- Added `currencySymbol` parameter (default: '€')
- Shows transactions with appropriate symbol

**HomeScreen** (`lib/screens/home_screen.dart`):
- Loads user preferences on initialization
- Passes currency symbol to SummaryCards and TransactionList
- Updates currency display when preferences change

### 10. Tests

**Model Tests** (`test/models/user_preferences_test.dart`):
- Tests for AppLanguage and AppCurrency enums
- Tests for UserPreferencesModel creation and conversion
- Tests for Firestore serialization/deserialization

**Service Tests** (`test/services/currency_conversion_service_test.dart`):
- Tests for currency conversion with provided rates
- Tests for same-currency conversion (no-op)

**Widget Tests** (`test/widgets/summary_cards_test.dart`):
- Tests for custom currency symbol display
- Tests for default Euro symbol

**Export Service Tests** (`test/services/export_service_test.dart`):
- Updated to expect Currency column in CSV
- Tests verify currency is included in exports

### 11. Documentation

**README.md**:
- Added multi-currency feature to features list
- Added language options to features list
- Updated CSV export documentation
- Added "Managing Preferences" section
- Added notes about currency changes

**MULTI_CURRENCY_SUPPORT.md**:
- Comprehensive guide to the feature
- Implementation details
- API documentation (Frankfurter)
- Code examples
- Troubleshooting guide
- Future enhancements

## Data Flow

### New User Registration
1. User creates account via registration flow
2. `AuthService.registerUser()` is called
3. User document created in Firestore
4. `PreferencesService.initializeDefaultPreferences()` called
5. Default preferences (EN, EUR) created in `users/{userId}/preferences/settings`

### Existing User Login
1. User signs in
2. `AuthService.getCurrentAppUser()` or `AuthService.updateLastLogin()` called
3. `PreferencesService.migrateUserPreferences()` called
4. If preferences don't exist, defaults are created
5. User can continue without interruption

### Changing Language
1. User selects language from Profile > Preferences dropdown
2. `_updateLanguage()` called
3. `PreferencesService.updateLanguage()` saves to Firestore
4. Success message shown
5. UI would update with translations (future enhancement)

### Changing Currency
1. User selects currency from Profile > Preferences dropdown
2. If same currency, no action taken
3. Confirmation dialog shown explaining the change
4. If confirmed:
   - `CurrencyConversionService.getEurToUsdRate()` or `.getUsdToEurRate()` called
   - Rate fetched from Frankfurter API
   - `PreferencesService.updateCurrency()` saves preference with rate
   - Success message shows the rate
   - UI updates to show new currency symbol
5. If cancelled, no changes made

### Loading Currency in UI
1. HomeScreen initialized
2. If user authenticated:
   - `PreferencesService.getPreferences()` called
   - Currency symbol extracted: `userPrefs.currency.symbol`
   - Symbol stored in state: `_currencySymbol`
3. Symbol passed to UI components:
   - `SummaryCards(currencySymbol: _currencySymbol)`
   - `TransactionList(currencySymbol: _currencySymbol)`
4. Components display amounts with appropriate symbol

## Firestore Data Structure

### User Preferences Document
Location: `users/{userId}/preferences/settings`

```json
{
  "language": "en",
  "currency": "EUR",
  "updatedAt": Timestamp,
  "conversionRate": 1.0987  // Optional, only set when currency changed
}
```

### Transaction Document (updated)
Location: `users/{userId}/projects/{projectId}/transactions/{transactionId}`

```json
{
  "id": 1,
  "description": "Venue rental",
  "amount": 500.00,
  "type": "expense",
  "category": "Venue",
  "date": "2024-01-15T10:30:00.000Z",
  "currency": "EUR"  // Optional, added for new transactions
}
```

## API Integration

### Frankfurter API
- **Base URL**: https://api.frankfurter.app
- **Endpoint Used**: `/latest?from={currency}&to={currency}`
- **Example**: `GET https://api.frankfurter.app/latest?from=EUR&to=USD`
- **Response**:
```json
{
  "amount": 1.0,
  "base": "EUR",
  "date": "2024-01-15",
  "rates": {
    "USD": 1.0987
  }
}
```

## Design Decisions

### 1. Display-Only Currency Change
**Decision**: Currency preference changes the symbol displayed but doesn't convert historical amounts.

**Rationale**: 
- Simpler implementation with less risk of data corruption
- Users can track original transaction currencies
- Conversion of historical data is complex (which rate to use? transaction date or change date?)
- Can be enhanced later with automatic conversion option

### 2. Default Preferences
**Decision**: Default to English and EUR.

**Rationale**:
- Euro is the most commonly used currency in the target market
- English is widely understood
- Easy to change for users who prefer otherwise

### 3. Preferences Stored in Firestore
**Decision**: Store preferences in Firestore subcollection, not locally.

**Rationale**:
- Syncs across devices
- Persists through app reinstalls
- Centralized storage with user data
- Can be backed up with user data

### 4. Migration on Login
**Decision**: Automatically create preferences for existing users on login.

**Rationale**:
- Non-disruptive to users
- Happens transparently
- Idempotent (safe to retry)
- Doesn't block login on failure

### 5. Currency in Transaction Model
**Decision**: Made currency field optional in Transaction model.

**Rationale**:
- Backward compatible with existing transactions
- Allows gradual migration
- Can default to EUR for legacy data

## Security Considerations

### Firestore Rules
- Users can only read/write their own preferences
- Rules use `isOwner()` helper to verify userId matches auth.uid
- No public access to preferences collection

### API Calls
- Frankfurter API is called client-side
- No sensitive data sent to API
- Public API with no authentication required
- HTTPS for secure transport

### Data Validation
- Currency and language enums prevent invalid values
- Firestore rules would reject invalid data (if added)
- UI dropdowns limit choices to valid options

## Testing Coverage

### Unit Tests
- ✅ UserPreferencesModel (Firestore conversion, defaults, enums)
- ✅ CurrencyConversionService (conversion logic)
- ✅ ExportService (CSV with currency column)

### Widget Tests
- ✅ SummaryCards (custom currency symbols, defaults)

### Integration Tests
- ⚠️ Not yet implemented (would require Firebase emulator)

## Future Enhancements

1. **Automatic Transaction Amount Conversion**
   - Convert historical amounts when currency changes
   - Use transaction date for rate lookup
   - Keep original amounts with conversion metadata

2. **More Currencies**
   - Add GBP, JPY, CAD, AUD, etc.
   - Use Frankfurter's full currency list

3. **Language Translations**
   - Implement i18n for Spanish and Catalan
   - Translate all UI strings
   - Support right-to-left languages

4. **Per-Transaction Currency**
   - Allow different currencies per transaction
   - Display all in user's preferred currency
   - Show original currency as metadata

5. **Historical Exchange Rates**
   - Use rate from transaction date
   - Show conversion rate in transaction details
   - Option to recalculate with current rates

6. **Currency Formatting**
   - Locale-specific number formatting
   - Thousand separators
   - Decimal precision by currency

## Known Limitations

1. **No Actual Translations**: Language setting doesn't change UI text yet
2. **No Historical Rates**: Always uses current exchange rate
3. **Two Currencies Only**: Limited to EUR and USD
4. **No Multi-Currency Projects**: All amounts in project assumed same currency
5. **Client-Side Conversion**: Rate fetching happens in client (could be Cloud Function)

## Deployment Notes

### Database Migration
- No database migration script needed
- Existing users get preferences on first login post-deploy
- Existing transactions work without currency field

### Configuration Changes
- No environment variables needed
- No configuration files to update
- Firestore rules need to be deployed

### Rollback Plan
If issues arise:
1. Revert Firestore rules to previous version
2. Revert code changes
3. User preferences remain in database but unused
4. No data loss

## Metrics and Monitoring

### What to Monitor
- Preference creation rate (should spike after deploy then stabilize)
- Currency change frequency
- API call failures to Frankfurter
- Preference load times

### Success Metrics
- % of users with non-default preferences
- Currency change adoption rate
- API success rate (should be >99%)
- No authentication/permission errors in logs

## Support and Troubleshooting

### Common Issues

**Preferences not loading**
- Check Firestore rules deployed
- Verify user authentication
- Check network connectivity
- Verify Firestore permissions

**Currency change fails**
- Check Frankfurter API status
- Verify network allows HTTPS to api.frankfurter.app
- Check browser console for errors
- Ensure user has network connectivity

**Wrong currency symbol displayed**
- Hard refresh the page
- Check preferences saved in Firestore console
- Verify state updates in React DevTools
- Check component receives currencySymbol prop

## Conclusion

The multi-currency support feature has been successfully implemented with:
- ✅ Minimal code changes following existing patterns
- ✅ SOLID principles and clean architecture
- ✅ Comprehensive testing
- ✅ Detailed documentation
- ✅ Backward compatibility
- ✅ Security best practices
- ✅ User-friendly interface

The implementation provides a solid foundation for future enhancements while delivering immediate value to users who need multi-currency support.
