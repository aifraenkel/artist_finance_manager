# Title: Remote Configuration System

## Labels
enhancement, infrastructure, low-priority

## Body

## Overview

Implement a remote configuration system for runtime configuration management, feature flags, A/B testing, and environment-specific settings without requiring app updates, as mentioned in `claude.md` section 12.

## Background

`claude.md` mentions:
- Remote config for runtime configuration
- Environment-specific configuration (dev, staging, prod)
- Feature flags support
- Configuration without hardcoded values

**Current State:** Configuration is likely hardcoded or in environment variables at build time.

## Requirements

### 1. Remote Configuration Service

**Features:**
- [ ] Fetch configuration from remote source at runtime
- [ ] Cache configuration locally
- [ ] Update configuration periodically
- [ ] Fallback to defaults if fetch fails
- [ ] Type-safe configuration access

**Example API:**
```dart
abstract class RemoteConfigService {
  Future<void> initialize();
  Future<void> fetch();
  T getValue<T>(String key, T defaultValue);
  bool isFeatureEnabled(String featureName);
}
```

### 2. Configuration Types

**Feature Flags:**
```dart
final bool darkModeEnabled = config.isFeatureEnabled('dark_mode');
final bool multiCurrencyEnabled = config.isFeatureEnabled('multi_currency');
final bool analyticsEnabled = config.isFeatureEnabled('analytics_dashboard');
```

**Configuration Values:**
```dart
final int maxTransactionsPerProject = config.getValue('max_transactions', 1000);
final String apiUrl = config.getValue('api_url', 'https://api.example.com');
final double currencyRefreshInterval = config.getValue('currency_refresh_hours', 24.0);
```

**A/B Testing:**
```dart
final String checkoutVariant = config.getValue('checkout_variant', 'control');
// Variants: 'control', 'variant_a', 'variant_b'
```

### 3. Environment-Specific Configuration

Support different configurations per environment:

```dart
// ✅ GOOD: Environment variables
const apiUrl = String.fromEnvironment('API_URL',
  defaultValue: 'https://api.example.com'
);

// ✅ GOOD: Config files per environment
final config = await loadConfig('config/${environment}.json');

// ❌ BAD: Hardcoded URLs
final apiUrl = 'http://localhost:3000';
```

**Environments:**
- Development (dev)
- Staging (staging)
- Production (prod)

### 4. Implementation Options

**Option A: Firebase Remote Config**
- Pros: Easy integration, free tier, dashboard for config management
- Cons: Vendor lock-in to Firebase

**Option B: Custom Backend Endpoint**
- Pros: Full control, can integrate with existing backend
- Cons: Need to build config management UI

**Option C: JSON Config Files + CDN**
- Pros: Simple, fast, low cost
- Cons: Manual deployment, no real-time updates

**Decision:** To be determined based on backend architecture choice.

### 5. Configuration Management

- [ ] Dashboard/UI for managing configuration
- [ ] Version control for configuration changes
- [ ] Audit log of configuration changes
- [ ] Rollback capability
- [ ] Environment promotion (dev → staging → prod)

### 6. Safety & Fallbacks

- [ ] Default values for all configurations
- [ ] Graceful degradation if remote config unavailable
- [ ] Local caching with TTL
- [ ] Configuration validation
- [ ] No blocking on config fetch (use cached/defaults)

## Use Cases

### 1. Feature Rollout
```dart
// Gradually roll out new feature to users
if (remoteConfig.isFeatureEnabled('new_analytics_dashboard')) {
  return NewAnalyticsDashboard();
} else {
  return LegacyDashboard();
}
```

### 2. Emergency Toggles
```dart
// Quickly disable a problematic feature without app update
if (remoteConfig.isFeatureEnabled('receipt_photo_upload')) {
  showReceiptUploadButton();
}
```

### 3. A/B Testing
```dart
// Test different UI variants
final variant = remoteConfig.getValue('transaction_form_variant', 'control');
switch (variant) {
  case 'simplified':
    return SimplifiedTransactionForm();
  case 'detailed':
    return DetailedTransactionForm();
  default:
    return StandardTransactionForm();
}
```

### 4. API Endpoints
```dart
// Change API endpoint without rebuilding app
final apiUrl = remoteConfig.getValue('api_base_url', 'https://api.example.com');
```

## Acceptance Criteria

- [ ] Remote configuration service implemented
- [ ] Feature flags supported
- [ ] Configuration values supported (string, int, bool, double)
- [ ] Local caching with fallbacks
- [ ] Environment-specific configuration
- [ ] Configuration dashboard/UI (or Firebase console)
- [ ] Documentation for adding new config values
- [ ] Integration with app initialization
- [ ] No blocking on config fetch

## Implementation Strategy

### Phase 1: Design & Planning
1. Choose remote config solution (Firebase, custom, or files)
2. Define configuration schema
3. Set up config storage/backend

### Phase 2: Infrastructure
1. Implement RemoteConfigService interface
2. Add local caching layer
3. Integrate with app initialization
4. Add fallback mechanisms

### Phase 3: Feature Flags
1. Implement feature flag system
2. Add flags for existing features
3. Document flag naming conventions
4. Create flag management process

### Phase 4: Configuration Values
1. Migrate hardcoded values to remote config
2. Add environment-specific configs
3. Set up config deployment pipeline
4. Document configuration management

## Testing Strategy

- [ ] Unit tests for RemoteConfigService
- [ ] Test fallback behavior (network unavailable)
- [ ] Test caching behavior
- [ ] Test environment-specific configs
- [ ] Test feature flag toggles

## Related Issues

- Relates to: #13 - Backend sync support (may share backend infrastructure)
- Enables: Gradual feature rollouts (#15, #16, #17, #18)
- Relates to: #31 - User consent (can use feature flags for consent flow variations)

## Related Files

- `lib/services/remote_config_service.dart` (new)
- `lib/main.dart` (initialize remote config)
- `config/` (new directory for environment configs)
- `claude.md` - Section 12

## Priority

**Low-Medium** - Nice to have, not critical for initial launch

**When to prioritize:**
- When preparing for public launch (need feature flags)
- When implementing A/B testing
- When need to change behavior without app updates
- When managing multiple environments

## Resources

- [Firebase Remote Config](https://firebase.google.com/docs/remote-config)
- [Feature Flags Best Practices](https://martinfowler.com/articles/feature-toggles.html)
