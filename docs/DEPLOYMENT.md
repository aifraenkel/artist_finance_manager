# Deployment Guide - GCP Cloud Run

## Table of Contents
- [Service Recommendation](#service-recommendation)
- [Prerequisites](#prerequisites)
- [GCP Setup Checklist](#gcp-setup-checklist)
- [Local Deployment](#local-deployment)
- [CI/CD Deployment](#cicd-deployment)
- [Rollback](#rollback)
- [Future Backend Extension](#future-backend-extension)

---

## Service Recommendation

### Why Google Cloud Run?

We've chosen **Google Cloud Run** as our deployment platform for the following reasons:

#### ✅ Current Benefits (Static Flutter Web)
- **Containerized deployment**: Packages the Flutter web app in a Docker container with nginx
- **Auto-scaling**: Scales to zero when not in use (cost-effective)
- **Zero-downtime deployments**: Gradual traffic shifting between versions
- **Built-in versioning**: Every deployment creates a new revision with automatic rollback support
- **HTTPS by default**: Automatic SSL/TLS certificates
- **Global CDN**: Built-in content delivery for fast worldwide access
- **Cost-effective**: Pay only for actual request time (scales to zero)

#### 🚀 Future-Proofing (When Adding Backend)
- **Same platform**: No migration needed when adding backend services
- **Easy extension**: Simply add backend routes to the same container
- **Database integration**: Easy connection to Cloud SQL, Firestore, or other GCP databases
- **Service-to-service auth**: Built-in IAM for secure microservices
- **Monitoring**: Integrated with Cloud Monitoring and Cloud Logging

#### 📊 Comparison with Alternatives

| Feature | Cloud Run | Firebase Hosting | App Engine |
|---------|-----------|------------------|------------|
| Static hosting | ✅ (via nginx) | ✅ Best for static | ✅ |
| Add backend later | ✅ Easy | ❌ Separate service | ✅ Coupled |
| Auto-scaling | ✅ To zero | ❌ Always on | ✅ Instances |
| Cost (low traffic) | 💰 Very low | 💰 Very low | 💰💰 Higher |
| Rollback | ✅ Built-in | ✅ Built-in | ✅ Built-in |
| Flexibility | ✅ High | ❌ Static only | ✅ High |
| Setup complexity | ⚡ Low | ⚡ Very low | ⚡⚡ Medium |

**Verdict**: Cloud Run offers the best balance of simplicity now and flexibility for future growth.

---

## Prerequisites

Before deploying, ensure you have:

1. **Google Cloud Account** with billing enabled
2. **gcloud CLI** installed and configured
   ```bash
   # Install gcloud CLI
   # macOS: https://cloud.google.com/sdk/docs/install-sdk#mac
   # Linux: https://cloud.google.com/sdk/docs/install-sdk#linux
   # Windows: https://cloud.google.com/sdk/docs/install-sdk#windows

   # Verify installation
   gcloud --version
   ```

3. **Docker** installed (for local builds and testing)
   ```bash
   # Verify installation
   docker --version
   ```

4. **Flutter SDK** (3.0.0 or higher)
   ```bash
   flutter --version
   ```

---

## GCP Setup Checklist

**Two ways to set up GCP:**

1. **Automated Setup** (recommended): Use `./scripts/setup-gcp.sh` with a configuration file
   - Handles everything automatically with validation and logging
   - Resume capability if any step fails
   - Smart defaults to minimize decisions
   - See [GCP_SETUP_QUICKSTART.md](GCP_SETUP_QUICKSTART.md#option-1-automated-setup-recommended) for details

2. **Manual Setup**: Follow the steps below for manual control

### Automated Setup (Recommended)

```bash
# 1. Copy and configure settings
cp scripts/.gcp_settings.example scripts/.gcp_settings
nano scripts/.gcp_settings  # Edit PROJECT_ID and BILLING_ACCOUNT_ID

# 2. Run setup script
./scripts/setup-gcp.sh

# Done! The script handles all steps below automatically.
```

See [GCP_SETUP_QUICKSTART.md](GCP_SETUP_QUICKSTART.md) for complete automated setup guide.

### Manual Setup

Follow these steps to set up your GCP project manually:

### 1. Create a GCP Project

```bash
# Set your project ID (must be globally unique)
export PROJECT_ID="artist-finance-manager"

# Create the project
gcloud projects create $PROJECT_ID --name="Artist Finance Manager"

# Set as current project
gcloud config set project $PROJECT_ID
```

### 2. Enable Required APIs

```bash
# Enable Cloud Run API
gcloud services enable run.googleapis.com

# Enable Container Registry API (for storing Docker images)
gcloud services enable containerregistry.googleapis.com

# Enable Cloud Build API (for CI/CD)
gcloud services enable cloudbuild.googleapis.com

# Enable Artifact Registry API (recommended for new projects)
gcloud services enable artifactregistry.googleapis.com
```

### 3. Enable Billing

Cloud Run requires billing to be enabled (but has a generous free tier).

1. Go to [Google Cloud Console](https://console.cloud.google.com/billing)
2. Select your project
3. Link a billing account

**Free Tier**: Cloud Run provides 2 million requests/month free.

### 4. Set Up Service Account for CI/CD

```bash
# Create a service account for GitHub Actions
gcloud iam service-accounts create github-actions \
    --display-name="GitHub Actions Deployment"

# Grant necessary permissions
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:github-actions@${PROJECT_ID}.iam.gserviceaccount.com" \
    --role="roles/run.admin"

gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:github-actions@${PROJECT_ID}.iam.gserviceaccount.com" \
    --role="roles/storage.admin"

gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:github-actions@${PROJECT_ID}.iam.gserviceaccount.com" \
    --role="roles/iam.serviceAccountUser"

# Create and download service account key
gcloud iam service-accounts keys create gcp-key.json \
    --iam-account=github-actions@${PROJECT_ID}.iam.gserviceaccount.com

# ⚠️ IMPORTANT: Keep this file secure! You'll add it to GitHub Secrets
```

### 5. Configure GitHub Secrets

Add these secrets to your GitHub repository:

1. Go to: `Settings` → `Secrets and variables` → `Actions` → `New repository secret`

2. Add the following secrets:

| Secret Name | Value | Description |
|-------------|-------|-------------|
| `GCP_PROJECT_ID` | Your project ID | e.g., `artist-finance-manager` |
| `GCP_SA_KEY` | Content of `gcp-key.json` | Full JSON service account key |
| `GCP_REGION` | Deployment region | e.g., `us-central1` |

```bash
# To get the service account key content:
cat gcp-key.json | pbcopy  # macOS - copies to clipboard
# Or just cat and copy manually:
cat gcp-key.json
```

### 6. Choose Deployment Region

Select a region close to your primary users:

- `us-central1` - Iowa, USA (recommended for US)
- `us-east1` - South Carolina, USA
- `europe-west1` - Belgium, Europe
- `asia-northeast1` - Tokyo, Asia

Full list: https://cloud.google.com/run/docs/locations

---

## Local Deployment

Deploy directly from your local machine using the deployment script.

### Quick Deploy (One Command)

```bash
# Deploy to GCP Cloud Run
./scripts/deploy.sh
```

This script will:
1. Run all tests (unit, widget, integration, E2E)
2. Build the Flutter web app
3. Build the Docker container
4. Push to Google Container Registry
5. Deploy to Cloud Run
6. Output the live URL

### Build Only (No Deploy)

```bash
# Just build the Flutter web app
flutter build web --release

# Just build the Docker image
docker build -t artist-finance-manager .

# Test the Docker image locally
docker run -p 8080:8080 artist-finance-manager
# Visit http://localhost:8080
```

### Configuration

Edit these environment variables in `scripts/deploy.sh` or set them before running:

```bash
export PROJECT_ID="artist-finance-manager"
export REGION="us-central1"
export SERVICE_NAME="artist-finance-manager"
```

---

## CI/CD Deployment

Deployments happen automatically when code is merged to `main`.

### How It Works

1. **Trigger**: Push to `main` branch
2. **Tests**: Runs all tests (unit, widget, integration, E2E)
3. **Build**: Builds Flutter web app
4. **Deploy**: Builds Docker image and deploys to Cloud Run
5. **Health Check**: Verifies the deployed app is accessible
6. **Rollback**: If health check fails, deployment is marked as failed (previous version remains active)

### Workflow File

The deployment workflow is defined in `.github/workflows/deploy-gcp.yml`.

### Monitoring Deployments

```bash
# View recent deployments
gcloud run revisions list --service=artist-finance-manager

# View service details
gcloud run services describe artist-finance-manager

# View logs
gcloud run services logs read artist-finance-manager

# Check live URL
gcloud run services describe artist-finance-manager --format="value(status.url)"
```

### Deployment Notifications

The workflow will:
- ✅ Comment on PRs with deployment status
- ❌ Fail the build if tests don't pass
- 🔗 Provide the live URL after successful deployment

---

## Rollback

Cloud Run maintains all previous revisions, making rollback simple and safe.

### Automatic Rollback

If the health check fails during deployment, the new revision will not receive traffic. The previous version remains active.

### Manual Rollback (Quick)

```bash
# List all revisions
gcloud run revisions list --service=artist-finance-manager

# Rollback to a specific revision
gcloud run services update-traffic artist-finance-manager \
    --to-revisions=artist-finance-manager-00005-xyz=100

# Or use the rollback script
./scripts/rollback.sh artist-finance-manager-00005-xyz
```

### Gradual Traffic Splitting (Canary Deployment)

```bash
# Send 90% traffic to current, 10% to new revision
gcloud run services update-traffic artist-finance-manager \
    --to-revisions=artist-finance-manager-00006-new=10,artist-finance-manager-00005-old=90

# Monitor metrics, then shift to 100% if all is well
gcloud run services update-traffic artist-finance-manager \
    --to-revisions=artist-finance-manager-00006-new=100
```

### Complete Rollback Process

1. **Identify the issue**
   ```bash
   # Check logs for errors
   gcloud run services logs read artist-finance-manager --limit=50
   ```

2. **Find the last good revision**
   ```bash
   gcloud run revisions list --service=artist-finance-manager
   ```

3. **Rollback**
   ```bash
   # Option 1: Use the script
   ./scripts/rollback.sh <REVISION_NAME>

   # Option 2: Manual rollback
   gcloud run services update-traffic artist-finance-manager \
       --to-revisions=<LAST_GOOD_REVISION>=100
   ```

4. **Verify**
   ```bash
   # Check the live URL
   curl -I $(gcloud run services describe artist-finance-manager --format="value(status.url)")
   ```

---

## Future Backend Extension

This deployment setup is designed to easily accommodate a backend when needed.

### How to Add a Backend

When you're ready to add a backend (API server, database, authentication), here's the migration path:

#### Option 1: Same Container (Recommended for Small Backend)

1. **Add backend code** to the project (e.g., `backend/` folder)
2. **Update Dockerfile** to include backend runtime (Node.js, Python, Go, etc.)
3. **Update nginx.conf** to proxy API routes to backend
   ```nginx
   # Static assets
   location / {
       root /usr/share/nginx/html;
       try_files $uri $uri/ /index.html;
   }

   # API routes
   location /api/ {
       proxy_pass http://localhost:3000;
   }
   ```
4. **Update start script** to run both nginx and backend
5. **Deploy** - same process, same Cloud Run service

#### Option 2: Separate Services (Recommended for Large Backend)

1. **Create new Cloud Run service** for backend API
   ```bash
   gcloud run deploy artist-finance-api \
       --source=./backend \
       --region=us-central1
   ```
2. **Update web app** to call backend API
3. **Configure CORS** and service-to-service authentication
4. **Deploy both services** independently

#### Option 3: Hybrid (Static + Serverless Functions)

1. Keep static web on Cloud Run
2. Use **Cloud Functions** for specific API endpoints
3. Use **Cloud Firestore** for real-time data sync
4. Update app to call Cloud Functions

### Database Options

When adding persistence:

- **Cloud Firestore**: NoSQL, real-time sync, great for mobile/web apps
- **Cloud SQL**: Managed PostgreSQL/MySQL for relational data
- **Cloud Spanner**: Global-scale relational database
- **Cloud Storage**: Object storage for files/images

All integrate seamlessly with Cloud Run.

### Authentication

Options for user authentication:

- **Firebase Authentication**: Easiest, supports Google, email, etc.
- **Identity Platform**: Enterprise version of Firebase Auth
- **Custom OAuth**: Roll your own with Cloud Run backend

---

## Cost Estimates

Cloud Run pricing (as of 2024):

**Free Tier (per month):**
- 2 million requests
- 360,000 GB-seconds of memory
- 180,000 vCPU-seconds

**For Artist Finance Manager (estimated):**
- **Low traffic** (1000 users/month): ~$5-10/month
- **Medium traffic** (10,000 users/month): ~$20-40/month
- **High traffic** (100,000 users/month): ~$100-200/month

💡 **Tip**: Enable scale-to-zero to minimize costs during low traffic periods.

---

## Troubleshooting

### Deployment Fails

```bash
# Check build logs
gcloud builds log $(gcloud builds list --limit=1 --format="value(id)")

# Check service logs
gcloud run services logs read artist-finance-manager --limit=50

# Check service status
gcloud run services describe artist-finance-manager
```

### App Not Loading

```bash
# Test the deployed URL
curl -I $(gcloud run services describe artist-finance-manager --format="value(status.url)")

# Check for errors in browser console
# Visit the URL in browser and open DevTools
```

### Permission Errors

```bash
# Verify service account permissions
gcloud projects get-iam-policy $PROJECT_ID \
    --flatten="bindings[].members" \
    --filter="bindings.members:serviceAccount:github-actions@*"

# Re-add permissions if needed (see GCP Setup Checklist)
```

---

## Additional Resources

- [Cloud Run Documentation](https://cloud.google.com/run/docs)
- [Cloud Run Pricing](https://cloud.google.com/run/pricing)
- [Flutter Web Deployment](https://docs.flutter.dev/deployment/web)
- [Docker for Flutter](https://docs.flutter.dev/deployment/docker)

---

**Questions or issues?** Open an issue on GitHub or consult the Cloud Run documentation.
