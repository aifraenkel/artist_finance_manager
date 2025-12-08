# Privacy Policy

**Last Updated:** December 3, 2024

## Overview

Art Finance Hub ("we", "our", or "the app") is committed to protecting your privacy. This Privacy Policy explains what data we collect, why we collect it, how we use it, and your rights regarding your data.

## Our Privacy-First Approach

We believe in privacy by design. Our app is built to minimize data collection and maximize user control:

- **Default to Privacy**: Analytics are disabled by default until you explicitly opt in
- **No Financial Data Tracking**: We never track your transaction amounts or descriptions
- **Transparent Collection**: We clearly explain what we collect and why
- **User Control**: You can change your privacy preferences at any time

## Data We Collect

### 1. Account Information

When you create an account, we collect:

- **Email address**: For authentication and account recovery
- **Name**: To personalize your experience
- **Account metadata**: Creation date, last login, login count

**Purpose**: To provide you with a secure, personalized account and enable cross-device sync.

**Legal Basis**: Contract performance (necessary to provide the service you requested)

### 2. Transaction Data (Local & Cloud Sync)

When you use the app, we store:

- **Transaction details**: Amount, description, category, type (income/expense), date
- **Transaction metadata**: Creation date, modification date

**Purpose**: To provide the core finance tracking functionality of the app.

**Storage**:
- **Local**: Stored on your device using SharedPreferences
- **Cloud**: Synced to Cloud Firestore when you're signed in (optional)

**Your Rights**: You can export or delete all your transaction data at any time.

**Legal Basis**: Contract performance (necessary to provide the service)

### 3. Analytics & Observability (Optional - Web Only)

**You control whether we collect analytics data.** If you opt in, we collect:

#### What We Collect:
- **Events**: Transaction actions (add, delete, load) - counts only, no amounts or descriptions
- **Performance Metrics**: Page load times, Web Vitals (LCP, FID, CLS)
- **Error Tracking**: JavaScript errors, stack traces, error context
- **Session Data**: Session duration, feature usage patterns
- **User Agent**: Browser type and version for compatibility

#### What We DON'T Collect:
- ❌ Transaction amounts
- ❌ Transaction descriptions
- ❌ Personal financial data
- ❌ Browsing history outside the app
- ❌ Geolocation data
- ❌ Device identifiers (unless explicitly used for session tracking)

**Purpose**: To improve app performance, fix bugs, and understand how features are used.

**Technology**: We use [Grafana Faro](https://grafana.com/docs/grafana-cloud/monitor-applications/frontend-observability/) for web analytics.

**Data Processor**: Grafana Labs (data sent to Grafana Cloud)

**Retention**: Analytics data is retained for 30 days by default.

**Legal Basis**: Consent (you explicitly opt in)

## How We Use Your Data

### Account Data
- Authenticate you when you sign in
- Enable cross-device sync of your transactions
- Send service-related emails (e.g., account verification, password reset)

### Transaction Data
- Display your financial summary (income, expenses, balance)
- Sync your data across devices (when signed in)
- Provide historical transaction records

### Analytics Data (if opted in)
- Monitor app performance and identify bottlenecks
- Track and fix errors proactively
- Understand feature usage to prioritize improvements
- Ensure compatibility across browsers and devices

## Data Sharing

We do **not** sell, rent, or share your personal data with third parties for marketing purposes.

We share data only in these limited circumstances:

1. **Service Providers**:
   - **Google Firebase/Firestore**: For authentication and cloud data storage
   - **Grafana Labs**: For analytics (only if you opt in)
   - **Email Service**: For sending authentication emails

2. **Legal Requirements**: If required by law or to protect our rights

3. **Business Transfers**: In the event of a merger or acquisition (with equivalent privacy protections)

## Data Storage & Security

### Where Your Data is Stored

- **Account & Transaction Data**: Google Cloud Firestore (data centers in the US)
- **Analytics Data**: Grafana Cloud (data centers in the US/EU, depending on configuration)
- **Local Data**: On your device (browser storage or app data)

### Security Measures

We implement industry-standard security measures:

- **Encryption in Transit**: All data transmitted over HTTPS/TLS
- **Encryption at Rest**: Cloud Firestore encrypts all data at rest
- **Authentication**: Email link authentication (passwordless)
- **Access Controls**: Strict database rules ensure users can only access their own data
- **Regular Audits**: We regularly review and update our security practices

### Data Retention

- **Account Data**: Retained while your account is active
- **Deleted Accounts**: Soft-deleted with 90-day recovery period, then permanently deleted
- **Transaction Data**: Retained while your account is active or until you delete it
- **Analytics Data**: Retained for 30 days (configurable in Grafana Cloud)

## Your Rights

Depending on your location, you may have the following rights:

### GDPR Rights (EU/EEA)

If you're in the EU/EEA, you have the right to:

1. **Access**: Request a copy of your personal data
2. **Rectification**: Correct inaccurate data
3. **Erasure**: Delete your data ("right to be forgotten")
4. **Portability**: Export your data in a machine-readable format
5. **Restriction**: Limit how we process your data
6. **Objection**: Object to data processing based on legitimate interests
7. **Withdraw Consent**: Opt out of analytics at any time

### CCPA Rights (California)

If you're in California, you have the right to:

1. **Know**: What personal information we collect and how we use it
2. **Delete**: Request deletion of your personal information
3. **Opt-Out**: Opt out of the "sale" of personal information (we don't sell data)
4. **Non-Discrimination**: Not be discriminated against for exercising your rights

### Exercising Your Rights

To exercise any of these rights:

1. **Analytics Opt-Out**: Go to Settings > Privacy & Data in the app
2. **Account Deletion**: Go to Profile > Delete Account
3. **Data Export**: Contact us at privacy@artistfinancemanager.com (or create a GitHub issue)
4. **Other Requests**: Email us at privacy@artistfinancemanager.com

<!-- TODO: Replace placeholder email with actual contact email before production -->

We will respond to requests within 30 days.

## Cookies & Tracking Technologies

The app uses:

- **Essential Cookies**: For authentication and session management (required)
- **Analytics Cookies**: For Grafana Faro tracking (optional, only if you opt in)

You can control analytics through the in-app privacy settings.

## Children's Privacy

Our app is not directed at children under 13 (or 16 in the EU). We do not knowingly collect data from children. If we learn we have collected data from a child, we will delete it promptly.

## International Data Transfers

Your data may be transferred to and processed in countries outside your country of residence (e.g., the United States). We ensure appropriate safeguards are in place:

- **Standard Contractual Clauses**: For EU data transfers
- **Adequate Security**: Encryption and access controls

## Changes to This Policy

We may update this Privacy Policy from time to time. We will notify you of significant changes by:

- Updating the "Last Updated" date
- Showing an in-app notification
- Sending an email (for material changes)

Continued use of the app after changes means you accept the updated policy.

## Contact Us

If you have questions about this Privacy Policy or our data practices:

- **Email**: privacy@artistfinancemanager.com
- **GitHub Issues**: [github.com/aifraenkel/artist_finance_manager/issues](https://github.com/aifraenkel/artist_finance_manager/issues)

<!-- TODO: Replace placeholder email with actual contact email before production -->

## Compliance & Certifications

We are committed to compliance with:

- **GDPR** (General Data Protection Regulation - EU)
- **CCPA** (California Consumer Privacy Act)
- **Google Cloud Platform Security**: Firebase/Firestore are SOC 2, ISO 27001 certified

---

## Summary

**We respect your privacy:**
- Analytics are **off by default**
- We **never** track your financial amounts or descriptions
- You can **delete your account** and all data anytime
- You can **change privacy settings** anytime
- We use **industry-standard security**

**Questions?** Contact us anytime. We're here to help.
