# Deployment Scripts

This directory contains scripts and configuration files for managing GCP Cloud Run deployments.

## Files

### Deployment Scripts

- **setup-gcp.sh** - First-time GCP project configuration
- **deploy.sh** - Build and deploy to Cloud Run
- **rollback.sh** - Rollback to previous deployment

### Configuration Files

- **Dockerfile** - Multi-stage Docker build for Flutter web app
- **nginx.conf** - Nginx configuration for serving the web app
- **.dockerignore** - Lives in project root, excludes files from Docker context

## Scripts

### setup-gcp.sh

Automated GCP project configuration script.

**Purpose**: Complete first-time GCP setup with minimal manual intervention.

**Usage**:
```bash
# 1. Configure settings
cp scripts/.gcp_settings.example scripts/.gcp_settings
nano scripts/.gcp_settings  # Edit PROJECT_ID and BILLING_ACCOUNT_ID

# 2. Run setup
./scripts/setup-gcp.sh
```

**Features**:
- ✅ Smart defaults (minimal configuration needed)
- ✅ Interactive prompts for missing values
- ✅ Suggests project IDs based on your Google account
- ✅ Lists available billing accounts
- ✅ Validates each step
- ✅ Logs everything to `.gcp_setup.log`
- ✅ Saves state to `.gcp_setup.state`
- ✅ Resume capability (re-run if fails)
- ✅ Optional GitHub secrets configuration

**Prerequisites**:
- `gcloud` CLI installed and authenticated
- `gh` CLI (optional, for GitHub secrets)

See [DEPLOYMENT.md - Prerequisites](../docs/DEPLOYMENT.md#prerequisites) for detailed installation instructions.

**What it does**:
1. Creates GCP project (or verifies if exists)
2. Links billing account
3. Enables required APIs
4. Creates service account
5. Grants IAM permissions
6. Generates service account key
7. (Optional) Configures GitHub secrets

---

### deploy.sh

One-step local deployment to GCP Cloud Run.

**Purpose**: Deploy the app from your local machine.

**Usage**:
```bash
# Full deployment with tests
./scripts/deploy.sh

# Skip tests (not recommended for production)
./scripts/deploy.sh --skip-tests
```

**What it does**:
1. Runs all tests (unit, widget, E2E)
2. Builds Flutter web app
3. Builds Docker image (using `scripts/Dockerfile`)
4. Pushes to Google Container Registry
5. Deploys to Cloud Run
6. Runs health checks
7. Displays deployment URL

**Prerequisites**:
- GCP project set up (run `setup-gcp.sh` first)
- `gcloud` CLI authenticated
- `docker` installed
- `flutter` SDK installed
- `curl` (for health checks)
- Environment variables:
  - `GCP_PROJECT_ID`
  - `GCP_REGION`
  - `GCP_SERVICE_NAME` (optional)

See [DEPLOYMENT.md - Prerequisites](../docs/DEPLOYMENT.md#prerequisites) for detailed installation instructions.

---

### rollback.sh

Rollback to a previous Cloud Run revision.

**Purpose**: Quickly revert to a previous version if deployment fails or has issues.

**Usage**:
```bash
# Interactive mode (lists revisions)
./scripts/rollback.sh

# Direct rollback to specific revision
./scripts/rollback.sh <REVISION_NAME>
```

**What it does**:
1. Lists all available revisions
2. Prompts for target revision (or uses provided one)
3. Validates revision exists
4. Shifts 100% traffic to target revision
5. Runs health checks
6. Displays rollback status

**Prerequisites**:
- `gcloud` CLI authenticated
- `curl` (for health checks)
- Existing Cloud Run service

See [DEPLOYMENT.md - Prerequisites](../docs/DEPLOYMENT.md#prerequisites) for detailed installation instructions.

---

## Environment Variables

All scripts support these environment variables:

| Variable | Description | Default |
|----------|-------------|---------|
| `GCP_PROJECT_ID` | Your GCP project ID | `artist-finance-manager` |
| `GCP_REGION` | Deployment region | `us-central1` |
| `GCP_SERVICE_NAME` | Cloud Run service name | `artist-finance-manager` |

Set them before running scripts:
```bash
export GCP_PROJECT_ID="my-project"
export GCP_REGION="us-east1"
./scripts/deploy.sh
```

Or set in `.gcp_settings` for `setup-gcp.sh`.

---

## Workflow

### First-Time Setup

1. **Configure GCP**:
   ```bash
   cp scripts/.gcp_settings.example scripts/.gcp_settings
   nano scripts/.gcp_settings
   ./scripts/setup-gcp.sh
   ```

2. **Deploy**:
   ```bash
   ./scripts/deploy.sh
   ```

### Regular Deployments

Use GitHub Actions (automatic on push to `main`) or:
```bash
./scripts/deploy.sh
```

### Emergency Rollback

```bash
./scripts/rollback.sh
```

---

## Logs and State

- **`.gcp_setup.log`**: Setup script log (excluded from git)
- **`.gcp_setup.state`**: Setup progress state (excluded from git)
- Scripts log to console and files

---

## Troubleshooting

### "Command not found: gcloud"

Install the Google Cloud SDK. See [DEPLOYMENT.md - Prerequisites](../docs/DEPLOYMENT.md#1-google-cloud-sdk-gcloud-cli) for detailed installation instructions.

### "Command not found: docker"

Install Docker. See [DEPLOYMENT.md - Prerequisites](../docs/DEPLOYMENT.md#2-docker) for detailed installation instructions.

### "Command not found: flutter"

Install the Flutter SDK. See [DEPLOYMENT.md - Prerequisites](../docs/DEPLOYMENT.md#3-flutter-sdk) for detailed installation instructions.

### "Not authenticated with gcloud"

```bash
gcloud auth login
gcloud auth application-default login
```

### "Permission denied" on scripts

```bash
chmod +x scripts/*.sh
```

### Setup fails at a step

1. Check `.gcp_setup.log` for details
2. Fix the issue (e.g., enable billing, fix project ID)
3. Re-run `./scripts/setup-gcp.sh` - it will resume

### Deployment fails

Check logs:
```bash
gcloud run services logs read artist-finance-manager --region=us-central1
```

---

## Security Notes

- Never commit `.gcp_settings` with real values
- Never commit `gcp-key.json` or `*-key.json`
- Never commit `.gcp_setup.log` (contains sensitive info)
- All sensitive files are in `.gitignore`

---

For more details, see:
- [DEPLOYMENT.md](../docs/DEPLOYMENT.md) - Complete deployment guide
- [GCP_SETUP_QUICKSTART.md](../docs/GCP_SETUP_QUICKSTART.md) - Quick setup guide
