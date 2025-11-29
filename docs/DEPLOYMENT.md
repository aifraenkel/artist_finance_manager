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

Before running deployment scripts, ensure you have the following tools installed:

### Required Tools

#### 1. Google Cloud SDK (gcloud CLI)

The Google Cloud SDK is required by all deployment scripts.

**Installation:**

<details>
<summary><strong>macOS</strong></summary>

```bash
# Using Homebrew (recommended)
brew install --cask google-cloud-sdk

# Or download installer
curl https://sdk.cloud.google.com | bash
exec -l $SHELL
```

</details>

<details>
<summary><strong>Linux</strong></summary>

```bash
# Debian/Ubuntu
sudo apt-get update && sudo apt-get install -y apt-transport-https ca-certificates gnupg curl
curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg
echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
sudo apt-get update && sudo apt-get install -y google-cloud-cli

# Or use installer script (any Linux)
curl https://sdk.cloud.google.com | bash
exec -l $SHELL
```

</details>

<details>
<summary><strong>Windows</strong></summary>

Download and run the installer from: https://cloud.google.com/sdk/docs/install#windows

Or use PowerShell:
```powershell
(New-Object Net.WebClient).DownloadFile("https://dl.google.com/dl/cloudsdk/channels/rapid/GoogleCloudSDKInstaller.exe", "$env:Temp\GoogleCloudSDKInstaller.exe")
& $env:Temp\GoogleCloudSDKInstaller.exe
```

</details>

**Verify installation:**
```bash
gcloud --version
# Expected output: Google Cloud SDK X.X.X
```

**Initial setup:**
```bash
gcloud auth login
gcloud config set project YOUR_PROJECT_ID
```

📖 [Official Documentation](https://cloud.google.com/sdk/docs/install)

---

#### 2. Docker

Docker is required for building container images for Cloud Run deployment.

**Installation:**

<details>
<summary><strong>macOS</strong></summary>

```bash
# Using Homebrew
brew install --cask docker

# Or download Docker Desktop from:
# https://docs.docker.com/desktop/install/mac-install/
```

After installation, launch Docker Desktop from Applications.

</details>

<details>
<summary><strong>Linux</strong></summary>

```bash
# Ubuntu/Debian
sudo apt-get update
sudo apt-get install -y docker.io
sudo systemctl start docker
sudo systemctl enable docker

# Add your user to docker group (to run without sudo)
sudo usermod -aG docker $USER
newgrp docker
```

</details>

<details>
<summary><strong>Windows</strong></summary>

Download and install Docker Desktop from: https://docs.docker.com/desktop/install/windows-install/

Requires WSL 2 backend. Follow the installer prompts.

</details>

**Verify installation:**
```bash
docker --version
# Expected output: Docker version X.X.X, build XXXXXXX

docker run hello-world
# Should print "Hello from Docker!"
```

📖 [Official Documentation](https://docs.docker.com/get-docker/)

---

#### 3. Flutter SDK

Flutter SDK (3.0.0 or higher) is required to build the web application.

**Installation:**

<details>
<summary><strong>macOS</strong></summary>

```bash
# Using Homebrew
brew install --cask flutter

# Or download manually
cd ~/development
curl -LO https://storage.googleapis.com/flutter_infra_release/releases/stable/macos/flutter_macos_arm64_3.24.0-stable.zip
unzip flutter_macos_arm64_3.24.0-stable.zip
export PATH="$PATH:$HOME/development/flutter/bin"
```

Add to your shell profile (`~/.zshrc` or `~/.bashrc`):
```bash
export PATH="$PATH:$HOME/development/flutter/bin"
```

</details>

<details>
<summary><strong>Linux</strong></summary>

```bash
# Using snap (recommended)
sudo snap install flutter --classic

# Or download manually
cd ~/development
curl -LO https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.24.0-stable.tar.xz
tar xf flutter_linux_3.24.0-stable.tar.xz
export PATH="$PATH:$HOME/development/flutter/bin"
```

Add to `~/.bashrc`:
```bash
export PATH="$PATH:$HOME/development/flutter/bin"
```

</details>

<details>
<summary><strong>Windows</strong></summary>

Download the Flutter SDK from: https://docs.flutter.dev/get-started/install/windows

Extract to `C:\flutter` and add `C:\flutter\bin` to your PATH environment variable.

Or use Chocolatey:
```powershell
choco install flutter
```

</details>

**Verify installation:**
```bash
flutter --version
# Expected output: Flutter X.X.X • channel stable

flutter doctor
# Should show green checkmarks for required components
```

📖 [Official Documentation](https://docs.flutter.dev/get-started/install)

---

#### 4. curl

curl is used for health checks and API calls. It's usually pre-installed on most systems.

**Installation (if needed):**

<details>
<summary><strong>macOS</strong></summary>

```bash
# Usually pre-installed, but if needed:
brew install curl
```

</details>

<details>
<summary><strong>Linux</strong></summary>

```bash
# Debian/Ubuntu
sudo apt-get install -y curl

# RHEL/CentOS/Fedora
sudo dnf install -y curl
```

</details>

<details>
<summary><strong>Windows</strong></summary>

curl is included in Windows 10 (build 17063+) by default.

For older versions, download from: https://curl.se/windows/

</details>

**Verify installation:**
```bash
curl --version
# Expected output: curl X.X.X (platform) ...
```

📖 [Official Documentation](https://curl.se/docs/)

---

### Optional Tools

#### GitHub CLI (gh)

The GitHub CLI is optional but useful for automatically configuring GitHub secrets during GCP setup.

**Installation:**

<details>
<summary><strong>macOS</strong></summary>

```bash
brew install gh
```

</details>

<details>
<summary><strong>Linux</strong></summary>

```bash
# Debian/Ubuntu
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
sudo apt update
sudo apt install gh
```

</details>

<details>
<summary><strong>Windows</strong></summary>

```powershell
# Using winget
winget install --id GitHub.cli

# Or using Chocolatey
choco install gh
```

</details>

**Verify installation:**
```bash
gh --version
# Expected output: gh version X.X.X (YYYY-MM-DD)

gh auth login
# Follow prompts to authenticate
```

📖 [Official Documentation](https://cli.github.com/)

---

### Prerequisites Quick Check

Run this command to verify all required tools are installed:

```bash
echo "Checking prerequisites..."
echo ""
echo "Google Cloud SDK:"
gcloud --version 2>/dev/null | head -1 || echo "  ❌ NOT INSTALLED"
echo ""
echo "Docker:"
docker --version 2>/dev/null || echo "  ❌ NOT INSTALLED"
echo ""
echo "Flutter:"
flutter --version 2>/dev/null | head -1 || echo "  ❌ NOT INSTALLED"
echo ""
echo "curl:"
curl --version 2>/dev/null | head -1 || echo "  ❌ NOT INSTALLED"
echo ""
echo "GitHub CLI (optional):"
gh --version 2>/dev/null | head -1 || echo "  ⚠️  NOT INSTALLED (optional)"
```

### Additional Requirements

- **Google Cloud Account** with billing enabled ([Create account](https://cloud.google.com/))
- **Git** for version control ([Download](https://git-scm.com/downloads))

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
