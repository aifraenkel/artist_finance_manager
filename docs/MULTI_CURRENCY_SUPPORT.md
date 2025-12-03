# Multi-Currency and Language Support

## Overview

The Art Finance Hub now supports multiple currencies and languages, allowing users to customize their experience based on their preferences.

## Features

### Language Support

Users can choose from three languages:
- **English** (en) - Default
- **Spanish** (es)
- **Catalan** (ca)

The language preference is stored per user and can be changed at any time from the Profile & Settings screen.

### Currency Support

Users can choose from two currencies:
- **Euro (€)** - EUR - Default
- **US Dollar ($)** - USD

#### Currency Conversion

When a user changes their currency preference:

1. A confirmation dialog is shown explaining the conversion process
2. The latest exchange rate is fetched from the [Frankfurter API](https://frankfurter.dev/)
3. The exchange rate is based on data from the European Central Bank
4. The conversion rate is stored with the user's preferences for future reference
5. The UI updates to display the new currency symbol

**Note:** In the current implementation, currency preference changes the display symbol (€ vs $) but does not automatically convert stored transaction amounts. This allows users to track which currency their transactions were originally recorded in. Future versions may include automatic conversion of historical data.

## Implementation Details

### Data Model

#### UserPreferencesModel (`lib/models/user_preferences.dart`)

Stores user preferences in Firestore:
```dart
class UserPreferencesModel {
  final String userId;
  final AppLanguage language;    // en, es, ca
  final AppCurrency currency;    // EUR, USD
  final DateTime updatedAt;
  final double? conversionRate;  // Last used conversion rate
}
```

#### Transaction Model Updates

Transactions now include an optional currency field for backward compatibility:
```dart
class Transaction {
  final String? currency;  // 'EUR' or 'USD'
  // ... other fields
}
```

### Services

#### PreferencesService (`lib/services/preferences_service.dart`)

Manages CRUD operations for user preferences in Firestore:
- `getPreferences(userId)` - Retrieves user preferences
- `savePreferences(preferences)` - Saves preferences to Firestore
- `updateLanguage(userId, language)` - Updates only language
- `updateCurrency(userId, currency, conversionRate)` - Updates currency with conversion
- `initializeDefaultPreferences(userId)` - Creates default preferences for new users
- `migrateUserPreferences(userId)` - Ensures existing users have preferences

#### CurrencyConversionService (`lib/services/currency_conversion_service.dart`)

Handles currency conversion using the Frankfurter API:
- `getEurToUsdRate()` - Fetches current EUR→USD rate
- `getUsdToEurRate()` - Fetches current USD→EUR rate
- `convertCurrency(amount, from, to, rate)` - Converts amount between currencies

### Firestore Structure

User preferences are stored in a subcollection under each user:

```
users/{userId}/preferences/settings
{
  language: 'en',
  currency: 'EUR',
  updatedAt: Timestamp,
  conversionRate: 1.12  // Optional
}
```

### Security Rules

Firestore security rules have been updated to allow users to read and write their own preferences:

```javascript
match /users/{userId}/preferences/{preferencesId} {
  allow read, write: if isOwner(userId);
}
```

## User Experience

### For New Users

1. During registration, default preferences (English, EUR) are automatically created
2. Users can change preferences at any time from Profile & Settings

### For Existing Users

1. On first login after the update, default preferences are automatically created
2. Migration happens transparently in the background
3. No data loss occurs - all transactions remain in EUR by default

### Changing Preferences

#### Language Change
- No data conversion required
- Change takes effect immediately
- UI labels update (when translations are implemented)

#### Currency Change
1. User selects new currency from dropdown
2. Confirmation dialog appears with:
   - Warning that conversion will be applied to all transactions
   - Information about the conversion rate source (ECB via Frankfurter)
3. If confirmed:
   - Latest exchange rate is fetched
   - User preference is updated with the new currency and rate
   - Currency symbol in UI updates to reflect new preference
   - A success message shows the fetched rate
4. If cancelled:
   - No changes are made

**Note:** The current implementation updates the display symbol but does not convert existing transaction amounts. Users should manually account for currency differences when switching preferences.

## CSV Export

The CSV export has been updated to include currency information:

```csv
Project name,Type,Category,Description,Amount,Currency,Datetime
Art Show,Expense,Venue,Venue rental,500.00,EUR,2024-01-15 10:30:00
```

Legacy transactions without a currency field default to EUR in the export.

## Testing

### Unit Tests

- `test/models/user_preferences_test.dart` - Tests for preference model
- `test/services/currency_conversion_service_test.dart` - Currency conversion tests

### Integration Testing

To test the feature:
1. Create a new account - verify default preferences (EN, EUR)
2. Add some transactions
3. Go to Profile & Settings
4. Change language - verify dropdown works
5. Change currency:
   - Verify confirmation dialog appears
   - Confirm the change
   - Verify success message with conversion rate
   - Check that currency symbols update in the UI

## API Dependencies

### Frankfurter API

- **URL**: https://api.frankfurter.app
- **Documentation**: https://frankfurter.dev/
- **Data Source**: European Central Bank
- **Rate Limits**: None documented
- **Free Tier**: Yes, completely free
- **Reliability**: High (hosted on reliable infrastructure)

Example API call:
```
GET https://api.frankfurter.app/latest?from=EUR&to=USD

Response:
{
  "amount": 1.0,
  "base": "EUR",
  "date": "2024-01-15",
  "rates": {
    "USD": 1.0987
  }
}
```

## Future Enhancements

Potential improvements for future versions:

1. **More Currencies**: Add support for GBP, JPY, etc.
2. **Language Translations**: Implement actual UI translations for Spanish and Catalan
3. **Historical Rates**: Option to use historical exchange rates based on transaction date
4. **Display-Only Conversion**: Option to convert for display without modifying stored data
5. **Auto-Update Rates**: Periodic background updates of conversion rates
6. **Currency per Transaction**: Allow different currencies per transaction instead of global

## Migration Notes

### For Existing Users

The migration happens automatically on user login:
1. `AuthService.getCurrentAppUser()` calls `_preferencesService.migrateUserPreferences()`
2. `AuthService.updateLastLogin()` also calls the migration (defensive)
3. Migration checks if preferences exist; if not, creates defaults
4. Process is idempotent - safe to call multiple times

### For New Users

New users get preferences automatically:
1. `AuthService.registerUser()` calls `_preferencesService.initializeDefaultPreferences()`
2. Default preferences (EN, EUR) are created in Firestore
3. User can immediately change preferences if desired

## Troubleshooting

### Currency Conversion Fails

If currency conversion fails:
- Check network connectivity
- Verify Frankfurter API is accessible
- Check browser console for error messages
- The operation will be cancelled and user notified

### Preferences Not Loading

If preferences don't load:
- Check user is authenticated
- Verify Firestore rules are deployed
- Check browser console for permission errors
- Migration will create defaults on next login

### Wrong Currency Symbol Displayed

If wrong symbol appears:
- Verify user preferences are saved in Firestore
- Check that UI components receive currencySymbol prop
- Ensure state updates after preference changes
- Hard refresh the page

## Code Examples

### Loading User Preferences

```dart
final preferencesService = PreferencesService();
final prefs = await preferencesService.getPreferences(userId);
print('Currency: ${prefs.currency.code}');
print('Symbol: ${prefs.currency.symbol}');
```

### Updating Currency with Conversion

```dart
final currencyService = CurrencyConversionService();
final rate = await currencyService.getEurToUsdRate();

if (rate != null) {
  await preferencesService.updateCurrency(
    userId,
    AppCurrency.usd,
    conversionRate: rate,
  );
}
```

### Displaying Currency in UI

```dart
SummaryCards(
  totalIncome: 1000.0,
  totalExpenses: 500.0,
  balance: 500.0,
  currencySymbol: userPrefs.currency.symbol, // '€' or '$'
)
```
