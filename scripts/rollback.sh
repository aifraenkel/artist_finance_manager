#!/bin/bash

# ============================================================================
# Artist Finance Manager - Cloud Run Rollback Script
# ============================================================================
# This script rolls back to a previous Cloud Run revision
#
# Prerequisites:
# - gcloud CLI installed and authenticated
#
# Usage:
#   ./scripts/rollback.sh [REVISION_NAME]
#   ./scripts/rollback.sh                    # Interactive mode
#   ./scripts/rollback.sh artist-finance-manager-00005-abc
# ============================================================================

set -e  # Exit on error
set -u  # Exit on undefined variable

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROJECT_ID="${GCP_PROJECT_ID:-artist-finance-manager}"
REGION="${GCP_REGION:-us-central1}"
SERVICE_NAME="${GCP_SERVICE_NAME:-artist-finance-manager}"

# ============================================================================
# Helper Functions
# ============================================================================

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_command() {
    if ! command -v "$1" &> /dev/null; then
        log_error "$1 is not installed. Please install it first."
        exit 1
    fi
}

# ============================================================================
# Pre-flight Checks
# ============================================================================

log_info "Starting rollback process..."
check_command "gcloud"

# Verify gcloud authentication
if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" &> /dev/null; then
    log_error "Not authenticated with gcloud. Run: gcloud auth login"
    exit 1
fi

# Set project
gcloud config set project "${PROJECT_ID}" --quiet

# ============================================================================
# Get Current Revision
# ============================================================================

log_info "Fetching current service information..."

CURRENT_REVISION=$(gcloud run services describe "${SERVICE_NAME}" \
    --region="${REGION}" \
    --format="value(status.latestReadyRevisionName)" 2>/dev/null || echo "")

if [ -z "${CURRENT_REVISION}" ]; then
    log_error "Could not find service '${SERVICE_NAME}' in region '${REGION}'"
    exit 1
fi

log_info "Current revision: ${CURRENT_REVISION}"

# ============================================================================
# List Available Revisions
# ============================================================================

log_info "Available revisions:"
echo ""

gcloud run revisions list \
    --service="${SERVICE_NAME}" \
    --region="${REGION}" \
    --format="table(
        metadata.name:label=REVISION,
        metadata.creationTimestamp.date('%Y-%m-%d %H:%M:%S'):label=CREATED,
        status.conditions[0].status:label=READY,
        spec.containers[0].image.split('/').slice(-1):label=IMAGE
    )" || {
    log_error "Failed to list revisions"
    exit 1
}

echo ""

# ============================================================================
# Select Revision to Rollback To
# ============================================================================

if [ $# -eq 0 ]; then
    # Interactive mode
    log_info "Enter the revision name to rollback to (or 'cancel' to abort):"
    read -r TARGET_REVISION

    if [ "${TARGET_REVISION}" = "cancel" ] || [ -z "${TARGET_REVISION}" ]; then
        log_warning "Rollback cancelled"
        exit 0
    fi
else
    # Use provided revision
    TARGET_REVISION="$1"
fi

# Validate revision exists
if ! gcloud run revisions describe "${TARGET_REVISION}" \
    --region="${REGION}" &> /dev/null; then
    log_error "Revision '${TARGET_REVISION}' not found"
    exit 1
fi

# Don't rollback to current revision
if [ "${TARGET_REVISION}" = "${CURRENT_REVISION}" ]; then
    log_error "Target revision is already the current revision"
    exit 1
fi

# ============================================================================
# Confirm Rollback
# ============================================================================

log_warning "You are about to rollback:"
echo "  From: ${CURRENT_REVISION}"
echo "  To:   ${TARGET_REVISION}"
echo ""

if [ -z "${CI:-}" ]; then
    # Interactive confirmation (skip in CI)
    read -p "Are you sure? (yes/no): " -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]es$ ]]; then
        log_warning "Rollback cancelled"
        exit 0
    fi
fi

# ============================================================================
# Perform Rollback
# ============================================================================

log_info "Rolling back to ${TARGET_REVISION}..."

gcloud run services update-traffic "${SERVICE_NAME}" \
    --region="${REGION}" \
    --to-revisions="${TARGET_REVISION}=100" \
    --quiet || {
    log_error "Rollback failed"
    exit 1
}

log_success "Rollback completed successfully!"

# ============================================================================
# Verify Rollback
# ============================================================================

log_info "Verifying rollback..."

NEW_CURRENT=$(gcloud run services describe "${SERVICE_NAME}" \
    --region="${REGION}" \
    --format="value(status.latestReadyRevisionName)")

if [ "${NEW_CURRENT}" = "${TARGET_REVISION}" ]; then
    log_success "Verification passed! Current revision is now ${TARGET_REVISION}"
else
    log_warning "Current revision is ${NEW_CURRENT}, expected ${TARGET_REVISION}"
fi

# Get service URL
SERVICE_URL=$(gcloud run services describe "${SERVICE_NAME}" \
    --region="${REGION}" \
    --format="value(status.url)")

# Health check
log_info "Running health check..."
if curl -f -s -o /dev/null -w "%{http_code}" "${SERVICE_URL}/health" | grep -q "200"; then
    log_success "Health check passed!"
else
    log_error "Health check failed. The app may not be working correctly."
    log_info "Check logs: gcloud run services logs read ${SERVICE_NAME} --region=${REGION}"
fi

# ============================================================================
# Display Post-Rollback Information
# ============================================================================

echo ""
echo "=========================================="
echo "  Rollback Successful!"
echo "=========================================="
echo "  Service:          ${SERVICE_NAME}"
echo "  Previous:         ${CURRENT_REVISION}"
echo "  Current:          ${TARGET_REVISION}"
echo "  URL:              ${SERVICE_URL}"
echo "=========================================="
echo ""

log_info "Useful commands:"
echo "  View logs:        gcloud run services logs read ${SERVICE_NAME} --region=${REGION}"
echo "  View service:     gcloud run services describe ${SERVICE_NAME} --region=${REGION}"
echo "  List revisions:   gcloud run revisions list --service=${SERVICE_NAME} --region=${REGION}"
echo ""
