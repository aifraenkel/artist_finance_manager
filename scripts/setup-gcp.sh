#!/bin/bash

# ============================================================================
# Artist Finance Manager - Automated GCP Setup Script
# ============================================================================
# This script automates the complete GCP Cloud Run deployment setup process.
#
# Features:
# - Reads configuration from .gcp_settings file
# - Validates each step before proceeding
# - Logs all actions to .gcp_setup.log
# - Saves state to .gcp_setup.state for resume capability
# - Automatically retries from failed steps
# - Provides smart defaults to minimize decisions
# - Optionally configures GitHub secrets automatically
#
# Prerequisites:
# - gcloud CLI installed and authenticated (run: gcloud auth login)
# - GitHub CLI (gh) installed (optional, for automatic GitHub secrets setup)
#
# Usage:
#   1. Copy scripts/.gcp_settings.example to scripts/.gcp_settings
#   2. Edit scripts/.gcp_settings with your values
#   3. Run: ./scripts/setup-gcp.sh
#   4. If setup fails, fix the issue and re-run (it will resume)
#
# ============================================================================

set -e  # Exit on error (but we'll handle errors ourselves)
set -u  # Exit on undefined variable
set -o pipefail  # Exit on pipe failure

# ============================================================================
# Configuration
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
SETTINGS_FILE="${SCRIPT_DIR}/.gcp_settings"
DEFAULT_LOG_FILE="${PROJECT_ROOT}/.gcp_setup.log"
DEFAULT_STATE_FILE="${PROJECT_ROOT}/.gcp_setup.state"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# ============================================================================
# Helper Functions
# ============================================================================

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1" | tee -a "${LOG_FILE:-$DEFAULT_LOG_FILE}"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1" | tee -a "${LOG_FILE:-$DEFAULT_LOG_FILE}"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1" | tee -a "${LOG_FILE:-$DEFAULT_LOG_FILE}"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "${LOG_FILE:-$DEFAULT_LOG_FILE}"
}

log_step() {
    echo -e "\n${CYAN}${BOLD}==>${NC} ${BOLD}$1${NC}\n" | tee -a "${LOG_FILE:-$DEFAULT_LOG_FILE}"
}

log_detail() {
    if [ "${VERBOSE:-false}" = "true" ]; then
        echo -e "    $1" | tee -a "${LOG_FILE:-$DEFAULT_LOG_FILE}"
    else
        echo "    $1" >> "${LOG_FILE:-$DEFAULT_LOG_FILE}"
    fi
}

check_command() {
    if ! command -v "$1" &> /dev/null; then
        log_error "$1 is not installed. Please install it first."
        return 1
    fi
    return 0
}

mark_step_complete() {
    echo "$1" >> "${STATE_FILE}"
    log_detail "Marked step complete: $1"
}

is_step_complete() {
    if [ -f "${STATE_FILE}" ]; then
        grep -q "^$1$" "${STATE_FILE}" 2>/dev/null
        return $?
    fi
    return 1
}

confirm() {
    if [ "${AUTO_CONFIRM:-false}" = "true" ]; then
        return 0
    fi

    local prompt="$1"
    local default="${2:-n}"

    if [ "$default" = "y" ]; then
        prompt="$prompt [Y/n]: "
    else
        prompt="$prompt [y/N]: "
    fi

    read -p "$prompt" -r
    echo

    if [ "$default" = "y" ]; then
        [[ $REPLY =~ ^[Nn] ]] && return 1 || return 0
    else
        [[ $REPLY =~ ^[Yy] ]] && return 0 || return 1
    fi
}

# ============================================================================
# Initialization
# ============================================================================

initialize() {
    log_step "Initializing GCP Setup"

    # Check if settings file exists
    if [ ! -f "${SETTINGS_FILE}" ]; then
        log_error "Settings file not found: ${SETTINGS_FILE}"
        log_info "Please copy scripts/.gcp_settings.example to scripts/.gcp_settings and configure it:"
        echo ""
        echo "  cp scripts/.gcp_settings.example scripts/.gcp_settings"
        echo "  nano scripts/.gcp_settings  # Edit with your values"
        echo "  ./scripts/setup-gcp.sh"
        echo ""
        exit 1
    fi

    # Load settings
    log_info "Loading settings from ${SETTINGS_FILE}..."
    # shellcheck source=/dev/null
    source "${SETTINGS_FILE}"

    # Set defaults if not provided
    GCP_REGION="${GCP_REGION:-us-central1}"
    GCP_SERVICE_NAME="${GCP_SERVICE_NAME:-artist-finance-manager}"
    GCP_SERVICE_ACCOUNT_NAME="${GCP_SERVICE_ACCOUNT_NAME:-github-actions}"
    GCP_SERVICE_ACCOUNT_DISPLAY_NAME="${GCP_SERVICE_ACCOUNT_DISPLAY_NAME:-GitHub Actions Deployment}"
    GCP_SERVICE_ACCOUNT_KEY_FILE="${GCP_SERVICE_ACCOUNT_KEY_FILE:-gcp-key.json}"
    VERBOSE="${VERBOSE:-false}"
    AUTO_CONFIRM="${AUTO_CONFIRM:-false}"
    LOG_FILE="${LOG_FILE:-$DEFAULT_LOG_FILE}"
    STATE_FILE="${STATE_FILE:-$DEFAULT_STATE_FILE}"
    GCP_APIS="${GCP_APIS:-run.googleapis.com containerregistry.googleapis.com cloudbuild.googleapis.com artifactregistry.googleapis.com}"
    GCP_SERVICE_ACCOUNT_ROLES="${GCP_SERVICE_ACCOUNT_ROLES:-roles/run.admin roles/storage.admin roles/iam.serviceAccountUser roles/artifactregistry.writer}"

    # Initialize log file
    echo "==============================================================================" > "${LOG_FILE}"
    echo "GCP Setup Log - $(date)" >> "${LOG_FILE}"
    echo "==============================================================================" >> "${LOG_FILE}"
    echo "" >> "${LOG_FILE}"

    log_success "Settings loaded successfully"

    # Check prerequisites
    log_info "Checking prerequisites..."
    check_command "gcloud" || exit 1
    check_command "curl" || exit 1

    # Check gcloud authentication
    if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" &> /dev/null; then
        log_error "Not authenticated with gcloud."
        log_info "Please run: gcloud auth login"
        exit 1
    fi

    local active_account
    active_account=$(gcloud auth list --filter=status:ACTIVE --format="value(account)" 2>/dev/null | head -1)
    log_success "Authenticated as: ${active_account}"

    log_success "All prerequisites met"
}

# ============================================================================
# Step 1: Validate and Suggest Project ID
# ============================================================================

validate_project_id() {
    if is_step_complete "validate_project_id"; then
        log_info "Step already complete: validate_project_id (skipping)"
        return 0
    fi

    log_step "Step 1: Validate Project ID"

    # If project ID not provided, suggest one
    if [ -z "${GCP_PROJECT_ID}" ]; then
        log_info "No project ID provided. Generating suggestions..."

        local account
        account=$(gcloud auth list --filter=status:ACTIVE --format="value(account)" | head -1)
        local username
        username=$(echo "$account" | cut -d'@' -f1 | tr '.' '-' | tr '_' '-')
        local timestamp
        timestamp=$(date +%Y%m)

        local suggestion1="artist-finance-${username}-${timestamp}"
        local suggestion2="artist-finance-mgr-${timestamp}"
        local suggestion3="artist-fm-${username}"

        echo ""
        log_warning "GCP_PROJECT_ID is not set in .gcp_settings"
        echo ""
        echo "Suggestions (must be globally unique):"
        echo "  1. ${suggestion1}"
        echo "  2. ${suggestion2}"
        echo "  3. ${suggestion3}"
        echo ""

        read -p "Enter project ID (or choose 1/2/3): " -r

        case $REPLY in
            1) GCP_PROJECT_ID="$suggestion1" ;;
            2) GCP_PROJECT_ID="$suggestion2" ;;
            3) GCP_PROJECT_ID="$suggestion3" ;;
            *) GCP_PROJECT_ID="$REPLY" ;;
        esac

        # Update settings file
        if confirm "Save '${GCP_PROJECT_ID}' to .gcp_settings?" "y"; then
            echo "GCP_PROJECT_ID=\"${GCP_PROJECT_ID}\"" >> "${SETTINGS_FILE}"
            log_success "Project ID saved to settings"
        fi
    fi

    # Validate project ID format
    if [[ ! "$GCP_PROJECT_ID" =~ ^[a-z][a-z0-9-]{4,28}[a-z0-9]$ ]]; then
        log_error "Invalid project ID format: ${GCP_PROJECT_ID}"
        log_info "Requirements: 6-30 chars, lowercase, start with letter, alphanumeric and hyphens only"
        exit 1
    fi

    log_success "Project ID validated: ${GCP_PROJECT_ID}"
    mark_step_complete "validate_project_id"
}

# ============================================================================
# Step 2: Create or Verify GCP Project
# ============================================================================

create_project() {
    if is_step_complete "create_project"; then
        log_info "Step already complete: create_project (skipping)"
        return 0
    fi

    log_step "Step 2: Create or Verify GCP Project"

    # Check if project already exists
    if gcloud projects describe "${GCP_PROJECT_ID}" &> /dev/null; then
        log_success "Project already exists: ${GCP_PROJECT_ID}"
        gcloud config set project "${GCP_PROJECT_ID}" --quiet
        mark_step_complete "create_project"
        return 0
    fi

    log_info "Project does not exist. Creating: ${GCP_PROJECT_ID}"

    if ! confirm "Create GCP project '${GCP_PROJECT_ID}'?" "y"; then
        log_error "User cancelled project creation"
        exit 1
    fi

    if gcloud projects create "${GCP_PROJECT_ID}" --name="Artist Finance Manager"; then
        log_success "Project created successfully"
        gcloud config set project "${GCP_PROJECT_ID}" --quiet
        mark_step_complete "create_project"
    else
        log_error "Failed to create project. It may already exist or name may be taken."
        log_info "Try a different project ID in .gcp_settings"
        exit 1
    fi
}

# ============================================================================
# Step 3: Link Billing Account
# ============================================================================

setup_billing() {
    if is_step_complete "setup_billing"; then
        log_info "Step already complete: setup_billing (skipping)"
        return 0
    fi

    log_step "Step 3: Link Billing Account"

    # Check if billing is already enabled
    if gcloud billing projects describe "${GCP_PROJECT_ID}" &> /dev/null; then
        local billing_account
        billing_account=$(gcloud billing projects describe "${GCP_PROJECT_ID}" --format="value(billingAccountName)" 2>/dev/null || echo "")

        if [ -n "$billing_account" ]; then
            log_success "Billing already enabled with account: ${billing_account}"
            mark_step_complete "setup_billing"
            return 0
        fi
    fi

    # If billing account not provided, list available ones
    if [ -z "${GCP_BILLING_ACCOUNT_ID}" ]; then
        log_info "No billing account specified. Listing available accounts..."

        local accounts
        accounts=$(gcloud billing accounts list --format="table(name,displayName,open)" 2>/dev/null || echo "")

        if [ -z "$accounts" ] || [ "$accounts" = "Listed 0 items." ]; then
            log_error "No billing accounts found"
            log_info "Please create a billing account at: https://console.cloud.google.com/billing"
            exit 1
        fi

        echo ""
        echo "$accounts"
        echo ""

        read -p "Enter billing account ID (format: XXXXXX-YYYYYY-ZZZZZZ): " -r
        GCP_BILLING_ACCOUNT_ID="$REPLY"

        # Update settings file
        if confirm "Save billing account to .gcp_settings?" "y"; then
            echo "GCP_BILLING_ACCOUNT_ID=\"${GCP_BILLING_ACCOUNT_ID}\"" >> "${SETTINGS_FILE}"
            log_success "Billing account saved to settings"
        fi
    fi

    log_info "Linking billing account: ${GCP_BILLING_ACCOUNT_ID}"

    if gcloud billing projects link "${GCP_PROJECT_ID}" \
        --billing-account="${GCP_BILLING_ACCOUNT_ID}"; then
        log_success "Billing account linked successfully"
        mark_step_complete "setup_billing"
    else
        log_error "Failed to link billing account"
        log_info "Please verify the billing account ID and try again"
        exit 1
    fi
}

# ============================================================================
# Step 4: Enable Required APIs
# ============================================================================

enable_apis() {
    if is_step_complete "enable_apis"; then
        log_info "Step already complete: enable_apis (skipping)"
        return 0
    fi

    log_step "Step 4: Enable Required APIs"

    log_info "Enabling APIs: ${GCP_APIS}"

    # Enable all APIs in one command
    # shellcheck disable=SC2086
    if gcloud services enable ${GCP_APIS} --project="${GCP_PROJECT_ID}"; then
        log_success "All APIs enabled successfully"
        mark_step_complete "enable_apis"
    else
        log_error "Failed to enable some APIs"
        log_info "This might be due to billing not being enabled yet. Wait a moment and try again."
        exit 1
    fi

    # Wait a bit for APIs to be fully enabled
    log_info "Waiting for APIs to be fully enabled (15 seconds)..."
    sleep 15
}

# ============================================================================
# Step 5: Create Service Account
# ============================================================================

create_service_account() {
    if is_step_complete "create_service_account"; then
        log_info "Step already complete: create_service_account (skipping)"
        return 0
    fi

    log_step "Step 5: Create Service Account"

    local sa_email="${GCP_SERVICE_ACCOUNT_NAME}@${GCP_PROJECT_ID}.iam.gserviceaccount.com"

    # Check if service account already exists
    if gcloud iam service-accounts describe "${sa_email}" --project="${GCP_PROJECT_ID}" &> /dev/null; then
        log_success "Service account already exists: ${sa_email}"
        mark_step_complete "create_service_account"
        return 0
    fi

    log_info "Creating service account: ${GCP_SERVICE_ACCOUNT_NAME}"

    if gcloud iam service-accounts create "${GCP_SERVICE_ACCOUNT_NAME}" \
        --display-name="${GCP_SERVICE_ACCOUNT_DISPLAY_NAME}" \
        --project="${GCP_PROJECT_ID}"; then
        log_success "Service account created: ${sa_email}"
        mark_step_complete "create_service_account"
    else
        log_error "Failed to create service account"
        exit 1
    fi
}

# ============================================================================
# Step 6: Grant IAM Roles
# ============================================================================

grant_iam_roles() {
    if is_step_complete "grant_iam_roles"; then
        log_info "Step already complete: grant_iam_roles (skipping)"
        return 0
    fi

    log_step "Step 6: Grant IAM Roles"

    local sa_email="${GCP_SERVICE_ACCOUNT_NAME}@${GCP_PROJECT_ID}.iam.gserviceaccount.com"

    for role in ${GCP_SERVICE_ACCOUNT_ROLES}; do
        log_info "Granting role: ${role}"

        if gcloud projects add-iam-policy-binding "${GCP_PROJECT_ID}" \
            --member="serviceAccount:${sa_email}" \
            --role="${role}" \
            --condition=None \
            --quiet > /dev/null; then
            log_success "Granted: ${role}"
        else
            log_error "Failed to grant role: ${role}"
            exit 1
        fi
    done

    log_success "All IAM roles granted"
    mark_step_complete "grant_iam_roles"
}

# ============================================================================
# Step 7: Create Service Account Key
# ============================================================================

create_service_account_key() {
    if is_step_complete "create_service_account_key"; then
        log_info "Step already complete: create_service_account_key (skipping)"
        return 0
    fi

    log_step "Step 7: Create Service Account Key"

    local sa_email="${GCP_SERVICE_ACCOUNT_NAME}@${GCP_PROJECT_ID}.iam.gserviceaccount.com"
    local key_path="${PROJECT_ROOT}/${GCP_SERVICE_ACCOUNT_KEY_FILE}"

    # Check if key file already exists
    if [ -f "${key_path}" ]; then
        log_warning "Key file already exists: ${key_path}"

        if ! confirm "Overwrite existing key file?" "n"; then
            log_info "Using existing key file"
            mark_step_complete "create_service_account_key"
            return 0
        fi
    fi

    log_info "Creating service account key..."

    if gcloud iam service-accounts keys create "${key_path}" \
        --iam-account="${sa_email}" \
        --project="${GCP_PROJECT_ID}"; then
        log_success "Service account key created: ${key_path}"
        log_warning "IMPORTANT: Keep this file secure! Never commit it to git!"
        mark_step_complete "create_service_account_key"
    else
        log_error "Failed to create service account key"
        exit 1
    fi
}

# ============================================================================
# Step 8: Configure GitHub Secrets (Optional)
# ============================================================================

configure_github_secrets() {
    if is_step_complete "configure_github_secrets"; then
        log_info "Step already complete: configure_github_secrets (skipping)"
        return 0
    fi

    log_step "Step 8: Configure GitHub Secrets (Optional)"

    # Check if GitHub settings are provided
    if [ -z "${GITHUB_REPOSITORY:-}" ] || [ -z "${GITHUB_TOKEN:-}" ]; then
        log_warning "GitHub repository or token not configured"
        log_info "You can manually configure GitHub secrets later"
        log_info "Required secrets:"
        echo "  - GCP_PROJECT_ID: ${GCP_PROJECT_ID}"
        echo "  - GCP_SA_KEY: <content of ${GCP_SERVICE_ACCOUNT_KEY_FILE}>"
        echo "  - GCP_REGION: ${GCP_REGION}"
        mark_step_complete "configure_github_secrets"
        return 0
    fi

    # Check if gh CLI is available
    if ! check_command "gh"; then
        log_warning "GitHub CLI (gh) not installed"
        log_info "Install from: https://cli.github.com/"
        log_info "Or manually configure GitHub secrets"
        mark_step_complete "configure_github_secrets"
        return 0
    fi

    log_info "Configuring GitHub secrets for: ${GITHUB_REPOSITORY}"

    local key_path="${PROJECT_ROOT}/${GCP_SERVICE_ACCOUNT_KEY_FILE}"

    # Set GitHub secrets using gh CLI
    export GH_TOKEN="${GITHUB_TOKEN}"

    log_info "Setting GCP_PROJECT_ID secret..."
    echo "${GCP_PROJECT_ID}" | gh secret set GCP_PROJECT_ID \
        --repo="${GITHUB_REPOSITORY}" || log_warning "Failed to set GCP_PROJECT_ID"

    log_info "Setting GCP_REGION secret..."
    echo "${GCP_REGION}" | gh secret set GCP_REGION \
        --repo="${GITHUB_REPOSITORY}" || log_warning "Failed to set GCP_REGION"

    log_info "Setting GCP_SA_KEY secret..."
    gh secret set GCP_SA_KEY \
        --repo="${GITHUB_REPOSITORY}" \
        < "${key_path}" || log_warning "Failed to set GCP_SA_KEY"

    log_success "GitHub secrets configured"
    mark_step_complete "configure_github_secrets"
}

# ============================================================================
# Summary
# ============================================================================

print_summary() {
    log_step "Setup Complete!"

    echo ""
    echo "=============================================================================="
    echo "  GCP Setup Summary"
    echo "=============================================================================="
    echo "  Project ID:       ${GCP_PROJECT_ID}"
    echo "  Region:           ${GCP_REGION}"
    echo "  Service Name:     ${GCP_SERVICE_NAME}"
    echo "  Service Account:  ${GCP_SERVICE_ACCOUNT_NAME}@${GCP_PROJECT_ID}.iam.gserviceaccount.com"
    echo "  Key File:         ${GCP_SERVICE_ACCOUNT_KEY_FILE}"
    echo "=============================================================================="
    echo ""

    log_info "Next steps:"
    echo ""
    echo "  1. Configure GitHub Secrets (if not already done):"
    echo "     - Go to: https://github.com/${GITHUB_REPOSITORY:-your-org/your-repo}/settings/secrets/actions"
    echo "     - Add these secrets:"
    echo "       • GCP_PROJECT_ID = ${GCP_PROJECT_ID}"
    echo "       • GCP_REGION = ${GCP_REGION}"
    echo "       • GCP_SA_KEY = <content of ${GCP_SERVICE_ACCOUNT_KEY_FILE}>"
    echo ""
    echo "  2. Deploy your app:"
    echo "     # Automatic (via GitHub Actions)"
    echo "     git push origin main"
    echo ""
    echo "     # Or manual (local deployment)"
    echo "     ./scripts/deploy.sh"
    echo ""
    echo "  3. View your project:"
    echo "     https://console.cloud.google.com/run?project=${GCP_PROJECT_ID}"
    echo ""

    log_success "All done! Your GCP environment is ready for deployment."

    echo ""
    log_warning "Security reminders:"
    echo "  - Never commit ${GCP_SERVICE_ACCOUNT_KEY_FILE} to git"
    echo "  - Never commit .gcp_settings with real values to git"
    echo "  - Store credentials securely"
    echo "  - Rotate service account keys periodically"
    echo ""

    log_info "Log file saved to: ${LOG_FILE}"
    log_info "State file saved to: ${STATE_FILE}"
}

# ============================================================================
# Main Execution
# ============================================================================

main() {
    echo ""
    echo "=============================================================================="
    echo "  Artist Finance Manager - GCP Setup"
    echo "=============================================================================="
    echo ""

    # Run setup steps
    initialize
    validate_project_id
    create_project
    setup_billing
    enable_apis
    create_service_account
    grant_iam_roles
    create_service_account_key
    configure_github_secrets

    # Print summary
    print_summary
}

# Run main function
main "$@"
