# Grafana Cloud Observability Setup Guide

This guide will help you configure Grafana Faro for web observability in the Artist Finance Manager app.

## Prerequisites

- Grafana Cloud free account (already created)
- Access to your Grafana Cloud instance

## Step 1: Set Up Grafana Faro in Grafana Cloud

1. **Log into Grafana Cloud**
   - Go to https://grafana.com and sign in to your account

2. **Navigate to Faro**
   - In your Grafana Cloud portal, click on "Frontend Observability" or "Faro"
   - If you don't see it, go to "Connections" → "Add new connection" → Search for "Faro"

3. **Create a New Faro App**
   - Click "Create new app" or "Add application"
   - Give it a name: `artist-finance-manager-web`
   - Select your environment (e.g., `production`)

4. **Get Your Collector URL**
   - After creating the app, you'll see a configuration page
   - Copy the **Collector URL** - it will look like:
     ```
     https://faro-collector-prod-us-east-0.grafana.net/collect/<YOUR_INSTANCE_ID>
     ```
   - Keep this URL handy for the next step

## Step 2: Configure the Web App

1. **Open the web configuration file**
   ```bash
   # Edit the file: web/index.html
   ```

2. **Update the Grafana Faro Configuration**
   - Find the `GRAFANA_FARO_CONFIG` object (around line 67)
   - Replace `YOUR_GRAFANA_CLOUD_COLLECTOR_URL` with your actual collector URL from Step 1

   **Before:**
   ```javascript
   const GRAFANA_FARO_CONFIG = {
     url: 'YOUR_GRAFANA_CLOUD_COLLECTOR_URL',
     app: {
       name: 'artist-finance-manager-web',
       version: '1.0.0',
       environment: 'production'
     }
   };
   ```

   **After:**
   ```javascript
   const GRAFANA_FARO_CONFIG = {
     url: 'https://faro-collector-prod-us-east-0.grafana.net/collect/YOUR_INSTANCE_ID',
     app: {
       name: 'artist-finance-manager-web',
       version: '1.0.0',
       environment: 'production'
     }
   };
   ```

3. **Optional: Adjust App Configuration**
   - **name**: Keep as `artist-finance-manager-web` or customize
   - **version**: Update when you release new versions
   - **environment**: Change to `development` or `staging` if needed

## Step 3: Build and Test

1. **Clean and rebuild the web app**
   ```bash
   flutter clean
   flutter pub get
   flutter build web --release
   ```

2. **Run the web app locally**
   ```bash
   flutter run -d chrome
   ```

3. **Test the integration**
   - Open the browser's developer console (F12)
   - You should see: `Grafana Faro initialized successfully`
   - If you see an error, check your collector URL

4. **Generate some events**
   - Add a few transactions (income/expense)
   - Delete a transaction
   - Refresh the page

## Step 4: View Data in Grafana Cloud

1. **Navigate to Grafana Cloud**
   - Go back to your Grafana Cloud portal
   - Click on "Explore" or "Dashboards"

2. **View Faro Data**
   - In the Explore view, select your Faro app data source
   - You should see:
     - **Events**: `transaction_added`, `transaction_deleted`, `transactions_loaded`
     - **Errors**: Any JavaScript errors or exceptions
     - **Logs**: Application logs
     - **Web Vitals**: Page performance metrics

3. **Create Dashboards** (Optional)
   - Go to "Dashboards" → "New Dashboard"
   - Add panels to visualize:
     - Transaction creation rate over time
     - Error rate
     - Page load performance
     - User sessions

## What's Being Tracked

### Custom Events
- `transaction_added` - When a user adds a transaction
  - Attributes: type, category, amount, total_transactions
- `transaction_deleted` - When a user deletes a transaction
  - Attributes: type, category, amount, remaining_transactions
- `transactions_loaded` - When transactions are loaded from storage
  - Attributes: count, load_time_ms

### Performance Metrics
- `transactions_load_time_ms` - Time to load transactions from local storage

### Automatic Instrumentation
The Faro SDK automatically tracks:
- **Console logs** - All console.log, console.error, etc.
- **JavaScript errors** - Unhandled exceptions and errors
- **Web Vitals** - Core Web Vitals (LCP, FID, CLS)
- **Sessions** - User session tracking

### Error Tracking
- Storage errors (loading/saving transactions)
- JSON parsing errors
- Any uncaught exceptions

## Example Queries

### Count transactions by type (in Grafana Explore)
```
{app="artist-finance-manager-web", event_name="transaction_added"} | type="income"
```

### View all errors
```
{app="artist-finance-manager-web"} |= "error"
```

### Average transaction load time
```
avg by (app) (faro_measurement_transactions_load_time_ms)
```

## Troubleshooting

### "Grafana Faro not configured - skipping initialization"
- This means the collector URL hasn't been configured yet
- Update `web/index.html` with your actual collector URL

### No data showing in Grafana Cloud
1. Check browser console for errors
2. Verify the collector URL is correct
3. Make sure you're generating events (add/delete transactions)
4. Wait a few minutes - there may be a small delay

### CORS errors
- Faro collector URLs are configured to accept cross-origin requests
- If you see CORS errors, contact Grafana Cloud support

## Advanced Configuration

### Multiple Environments
To track different environments (dev, staging, prod):

1. Use environment variables or build flags
2. Set different `environment` values in the config
3. Filter by environment in Grafana dashboards

### Custom User Tracking
To track specific users (if you add authentication later):

```javascript
// In your Dart code
_observability.setUser(
  'user-123',
  email: 'user@example.com',
  username: 'artist_name',
);
```

### Session Replay (Optional)
Grafana Faro supports session replay to see exactly what users experienced:

1. In Grafana Cloud, enable Session Replay for your Faro app
2. Add the Session Replay instrumentation to `web/index.html`:
   ```javascript
   new window.GrafanaFaroWebSdk.SessionReplayInstrumentation(),
   ```

## Free Tier Limits

Grafana Cloud free tier includes:
- **10,000 active series** for metrics
- **50 GB** of logs per month
- **50 GB** of traces per month
- **14 days** retention

This should be more than enough for your personal project and moderate traffic.

## Next Steps

Once configured, you can:
1. Monitor real-time user activity
2. Track errors and fix issues proactively
3. Analyze performance bottlenecks
4. Understand user behavior and feature usage

## Resources

- [Grafana Faro Documentation](https://grafana.com/docs/grafana-cloud/faro-web-sdk/)
- [Grafana Cloud Portal](https://grafana.com/auth/sign-in)
- [Web Vitals Guide](https://web.dev/vitals/)
