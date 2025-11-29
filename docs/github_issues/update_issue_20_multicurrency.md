# Update for Issue #20: Multi-currency support

## Current Description
"Add support for multiple currencies to help artists working internationally track finances in different currencies."

## Suggested Enhanced Description

---

## Overview

Add comprehensive multi-currency support to help artists working internationally track finances in different currencies, with proper architecture as specified in `claude.md` section 5.

## Background

Artists often work across borders and need to track income and expenses in multiple currencies. The implementation must follow the architecture pattern defined in `claude.md`:

**Architecture Pattern (from claude.md section 5):**
```
Stored Value (canonical currency) → Currency Service → Displayed Value (user's preferred currency)
```

**Key Principle:** Store in canonical currency, display in user's preferred currency.

## Requirements

### 1. Canonical Storage

**All amounts stored in USD cents (canonical currency):**

```dart
class Transaction {
  final int amountInCents;  // Always USD cents
  final String displayCurrency;  // User's preference at time of creation
  final DateTime createdAt;
}
```

**Why USD cents?**
- Avoid floating-point errors
- Consistent storage format
- Easy conversion to any currency
- Industry standard

### 2. Currency Service

Create abstraction for currency operations:

```dart
abstract class CurrencyService {
  /// Convert amount from one currency to another
  int convertAmount(int amountInCents, String fromCurrency, String toCurrency);

  /// Format amount for display in target currency
  String formatAmount(int amountInCents, String targetCurrency);

  /// Get current exchange rate
  double getExchangeRate(String fromCurrency, String toCurrency);

  /// Refresh exchange rates from API
  Future<void> refreshExchangeRates();
}
```

### 3. Supported Currencies

**Priority 1 (Initial Release):**
- USD - US Dollar
- EUR - Euro
- GBP - British Pound
- CAD - Canadian Dollar
- AUD - Australian Dollar
- JPY - Japanese Yen

**Priority 2 (Future):**
- All major world currencies
- Cryptocurrency support (BTC, ETH)
- User-requested currencies

### 4. Exchange Rate Management

**Options:**
- **Option A:** Real-time API (e.g., exchangerate-api.io, fixer.io)
- **Option B:** Cached rates with periodic refresh
- **Option C:** Manual rate entry (fallback)

**Requirements:**
- [ ] Fetch exchange rates from reliable API
- [ ] Cache rates locally (avoid excessive API calls)
- [ ] Refresh rates daily (or user-triggered)
- [ ] Graceful fallback if API unavailable
- [ ] Display last update time

### 5. User Experience

**Currency Selection:**
- [ ] User selects preferred display currency in preferences
- [ ] Currency switcher in settings
- [ ] Dynamic UI update when currency changes (no app restart)
- [ ] Remember currency preference across sessions

**Transaction Input:**
- [ ] Input amount in any supported currency
- [ ] Automatically convert to canonical currency (USD cents) for storage
- [ ] Display original currency in transaction list
- [ ] Show equivalent in user's preferred currency

**Display:**
- [ ] All amounts display in user's preferred currency
- [ ] Proper currency formatting (symbols, decimal places)
- [ ] Locale-aware number formatting
- [ ] Option to see amounts in original currency

### 6. Implementation Pattern

```dart
// ✅ GOOD: Canonical storage with display conversion
class Transaction {
  final int amountInCents;  // Always USD cents
  final String originalCurrency;  // Currency used when created
  final String displayCurrency;  // User's current preference

  // Convert and format for display
  String getDisplayAmount(CurrencyService currencyService) {
    return currencyService.formatAmount(
      amountInCents,
      displayCurrency,
    );
  }
}

// ❌ BAD: Ambiguous storage
class Transaction {
  final double amount;  // Which currency? Floating point errors!
}
Text('\$${amount}')  // What if user prefers EUR?
```

### 7. Data Migration

- [ ] Migrate existing transactions to canonical format
- [ ] Assume existing amounts are in USD
- [ ] Set `originalCurrency` to USD for existing transactions
- [ ] No data loss during migration

## Acceptance Criteria

- [ ] Currency preference system implemented
- [ ] User can select preferred display currency
- [ ] All amounts stored in canonical currency (USD cents)
- [ ] CurrencyService abstraction created
- [ ] Exchange rate API integrated
- [ ] Exchange rates cached locally
- [ ] UI displays amounts in user's preferred currency
- [ ] Transaction input supports multiple currencies
- [ ] Proper currency formatting (symbols, decimals)
- [ ] Locale-aware number formatting
- [ ] At least 6 major currencies supported
- [ ] Data migration completed for existing transactions
- [ ] Comprehensive tests for currency conversion
- [ ] Documentation updated

## Implementation Strategy

### Phase 1: Foundation
1. Design CurrencyService interface
2. Choose exchange rate API
3. Set up currency data models
4. Define canonical storage format

### Phase 2: Backend & Storage
1. Update Transaction model (add amountInCents, originalCurrency)
2. Implement CurrencyService
3. Integrate exchange rate API
4. Add local caching
5. Migrate existing data

### Phase 3: User Preferences
1. Add currency preference to preferences system
2. Create currency picker UI
3. Integrate with preferences service
4. Test reactive UI updates

### Phase 4: UI Integration
1. Update transaction input to support multiple currencies
2. Update display logic to use CurrencyService
3. Add currency formatting
4. Test all UI flows

### Phase 5: Polish & Testing
1. Add manual exchange rate entry (fallback)
2. Display last rate update time
3. Comprehensive testing
4. Documentation

## Technical Details

**Exchange Rate API Options:**
- [exchangerate-api.io](https://www.exchangerate-api.com/) - Free tier: 1,500 requests/month
- [fixer.io](https://fixer.io/) - Free tier: 100 requests/month
- [currencyapi.com](https://currencyapi.com/) - Free tier: 300 requests/month

**Currency Formatting:**
```dart
import 'package:intl/intl.dart';

String formatCurrency(int amountInCents, String currency) {
  final amount = amountInCents / 100;
  final formatter = NumberFormat.currency(
    locale: 'en_US',  // Use user's locale
    symbol: currencySymbols[currency],
  );
  return formatter.format(amount);
}
```

## Related Issues

- Blocked by: User Preferences System Architecture (for currency preference)
- Relates to: i18n System (locale-aware number formatting)
- Relates to: #13 - Backend sync (sync exchange rates)

## Related Files

- `lib/services/currency_service.dart` (new)
- `lib/models/transaction.dart` (update)
- `lib/models/currency.dart` (new)
- `lib/services/preferences_service.dart` (currency preference)
- `claude.md` - Section 5

## Priority

**Medium** - Important for international users, but not critical for initial launch
