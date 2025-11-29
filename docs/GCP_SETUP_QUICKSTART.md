# GCP Setup Quickstart Guide

This guide provides two ways to set up GCP deployment:
1. **Automated Setup** (recommended) - Uses a script with smart defaults
2. **Manual Setup** - Step-by-step commands

For full details, see [DEPLOYMENT.md](DEPLOYMENT.md).

## Prerequisites Checklist

Before proceeding, ensure you have all required tools installed. For detailed installation instructions, see [DEPLOYMENT.md - Prerequisites](DEPLOYMENT.md#prerequisites).

### Required Tools

| Tool | Required | Verify Command | Installation Guide |
|------|----------|----------------|-------------------|
| Google Cloud SDK | ✅ | `gcloud --version` | [Install](DEPLOYMENT.md#1-google-cloud-sdk-gcloud-cli) |
| Docker | ✅ | `docker --version` | [Install](DEPLOYMENT.md#2-docker) |
| Flutter SDK | ✅ | `flutter --version` | [Install](DEPLOYMENT.md#3-flutter-sdk) |
| curl | ✅ | `curl --version` | [Install](DEPLOYMENT.md#4-curl) |
| GitHub CLI | ⚪ Optional | `gh --version` | [Install](DEPLOYMENT.md#github-cli-gh) |

### Quick Verification

```bash
# Run this to check all prerequisites at once
gcloud --version && docker --version && flutter --version && curl --version
```

### Authentication

After installing the tools, authenticate with Google Cloud:

```bash
gcloud auth login
gcloud auth application-default login
```

---

## Option 1: Automated Setup (Recommended)

The automated setup script handles everything with validation, logging, and resume capability.

### Quick Start (3 steps)

1. **Copy and configure settings file:**
   ```bash
   cp scripts/.gcp_settings.example scripts/.gcp_settings
   nano scripts/.gcp_settings  # Edit PROJECT_ID and BILLING_ACCOUNT_ID (minimal edits needed)
   ```

2. **Run the setup script:**
   ```bash
   ./scripts/setup-gcp.sh
   ```

3. **Done!** The script will:
   - ✅ Create GCP project (or verify if exists)
   - ✅ Enable billing
   - ✅ Enable required APIs
   - ✅ Create service account with proper permissions
   - ✅ Generate service account key
   - ✅ Optionally configure GitHub secrets
   - ✅ Log everything to `.gcp_setup.log`
   - ✅ Save state to `.gcp_setup.state` for resume

### Features

- **Smart Defaults**: Minimal configuration required (just project ID and billing account)
- **Suggestions**: Script suggests project IDs based on your Google account
- **Validation**: Each step is validated before proceeding
- **Logging**: Complete log saved to `.gcp_setup.log`
- **Resume Capability**: If setup fails, fix the issue and re-run - it resumes from where it left off
- **Interactive**: Guides you through any missing configuration
- **Safe**: Confirms before making changes

### Configuration File (.gcp_settings)

Only two settings are required:

```bash
# REQUIRED: Your unique GCP project ID (script can suggest one)
GCP_PROJECT_ID=""

# REQUIRED: Your billing account ID (script can list available ones)
GCP_BILLING_ACCOUNT_ID=""
```

All other settings have smart defaults:
- `GCP_REGION="us-central1"` (Iowa, USA - best for US users)
- `GCP_SERVICE_NAME="artist-finance-manager"`
- Service account settings (pre-configured)
- GitHub repository info (optional)

See `scripts/.gcp_settings.example` for all options and descriptions.

### If Setup Fails

The script saves progress, so you can resume:

1. Check the log: `cat .gcp_setup.log`
2. Fix the issue (e.g., enable billing, fix project ID)
3. Re-run: `./scripts/setup-gcp.sh`
4. It will skip completed steps and resume

### Manual GitHub Secrets

If you didn't provide `GITHUB_TOKEN` in settings:

1. Go to: `https://github.com/YOUR_ORG/YOUR_REPO/settings/secrets/actions`
2. Add secrets:
   - `GCP_PROJECT_ID` = Your project ID
   - `GCP_SA_KEY` = Content of `gcp-key.json`
   - `GCP_REGION` = Your region (e.g., `us-central1`)

---

## Option 2: Manual Setup

If you prefer manual control, follow these steps.

### 5-Minute Manual Setup

### 1. Create GCP Project

```bash
# Set your unique project ID
export PROJECT_ID="artist-finance-manager"
export REGION="us-central1"

# Create project
gcloud projects create $PROJECT_ID --name="Artist Finance Manager"
gcloud config set project $PROJECT_ID
```

### 2. Enable Required APIs

```bash
gcloud services enable run.googleapis.com \
    containerregistry.googleapis.com \
    cloudbuild.googleapis.com \
    artifactregistry.googleapis.com
```

### 3. Enable Billing

Visit: https://console.cloud.google.com/billing

Link a billing account to your project.

### 4. Create Service Account for CI/CD

```bash
# Create service account
gcloud iam service-accounts create github-actions \
    --display-name="GitHub Actions Deployment"

# Grant permissions
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:github-actions@${PROJECT_ID}.iam.gserviceaccount.com" \
    --role="roles/run.admin"

gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:github-actions@${PROJECT_ID}.iam.gserviceaccount.com" \
    --role="roles/storage.admin"

gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:github-actions@${PROJECT_ID}.iam.gserviceaccount.com" \
    --role="roles/iam.serviceAccountUser"

# Create and download key
gcloud iam service-accounts keys create gcp-key.json \
    --iam-account=github-actions@${PROJECT_ID}.iam.gserviceaccount.com
```

### 5. Configure GitHub Secrets

Go to: `GitHub Repo → Settings → Secrets and variables → Actions`

Add these secrets:

| Secret Name | Value |
|-------------|-------|
| `GCP_PROJECT_ID` | Your project ID (e.g., `artist-finance-manager`) |
| `GCP_SA_KEY` | Full content of `gcp-key.json` file |
| `GCP_REGION` | Your region (e.g., `us-central1`) |

```bash
# Copy key content (macOS)
cat gcp-key.json | pbcopy

# Or just display it
cat gcp-key.json
```

## Deploy!

### Option 1: Automatic (CI/CD)

```bash
# Just merge to main
git push origin main
```

GitHub Actions will automatically deploy.

### Option 2: Manual (Local)

```bash
# One command deployment
./scripts/deploy.sh
```

## Verify Deployment

```bash
# Get service URL
gcloud run services describe artist-finance-manager \
    --region=$REGION \
    --format="value(status.url)"

# Check logs
gcloud run services logs read artist-finance-manager
```

## Common Regions

- `us-central1` - Iowa, USA (recommended for US users)
- `us-east1` - South Carolina, USA
- `europe-west1` - Belgium, Europe
- `asia-northeast1` - Tokyo, Asia

## Cost Estimate

**Free tier**: 2 million requests/month

**Typical costs**:
- Low traffic (1K users/month): ~$5-10
- Medium traffic (10K users/month): ~$20-40
- High traffic (100K users/month): ~$100-200

## Troubleshooting

### "Permission denied" errors

```bash
# Re-authenticate
gcloud auth login
gcloud auth application-default login
```

### "Project not found"

```bash
# Verify project exists
gcloud projects list
gcloud config set project $PROJECT_ID
```

### "API not enabled"

```bash
# Re-enable required APIs
gcloud services enable run.googleapis.com
```

## Next Steps

- ✅ Review full documentation: [DEPLOYMENT.md](DEPLOYMENT.md)
- ✅ Set up monitoring: [Cloud Console](https://console.cloud.google.com/run)
- ✅ Configure custom domain (optional)
- ✅ Set up alerts for errors/downtime

## Quick Commands Reference

```bash
# Deploy
./scripts/deploy.sh

# Rollback
./scripts/rollback.sh

# View logs
gcloud run services logs read artist-finance-manager

# View service details
gcloud run services describe artist-finance-manager

# List all revisions
gcloud run revisions list --service=artist-finance-manager

# Delete service (if needed)
gcloud run services delete artist-finance-manager
```

---

**Need help?** See [DEPLOYMENT.md](DEPLOYMENT.md) for detailed documentation.
