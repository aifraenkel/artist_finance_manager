#!/bin/bash

# ============================================================================
# Artist Finance Manager - GCP Cloud Run Deployment Script
# ============================================================================
# This script deploys the Flutter web app to Google Cloud Run
# It can be run locally or in CI/CD pipelines
#
# Prerequisites:
# - gcloud CLI installed and authenticated
# - Docker installed
# - Flutter SDK installed
# - All tests passing
#
# Usage:
#   ./scripts/deploy.sh [--skip-tests]
#
# Options:
#   --skip-tests    Skip running tests (not recommended for production)
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
PROJECT_ID="${GCP_PROJECT_ID:-artist-manager-479514}"
REGION="${GCP_REGION:-us-central1}"
SERVICE_NAME="${GCP_SERVICE_NAME:-artist-finance-manager}"
IMAGE_NAME="gcr.io/${PROJECT_ID}/${SERVICE_NAME}"
SKIP_TESTS=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --skip-tests)
            SKIP_TESTS=true
            shift
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            exit 1
            ;;
    esac
done

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

log_info "Starting deployment process..."
log_info "Project: ${PROJECT_ID}"
log_info "Region: ${REGION}"
log_info "Service: ${SERVICE_NAME}"

# Check required commands
log_info "Checking prerequisites..."
check_command "gcloud"
check_command "docker"
check_command "flutter"

# Verify gcloud authentication
if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" &> /dev/null; then
    log_error "Not authenticated with gcloud. Run: gcloud auth login"
    exit 1
fi
log_success "Authenticated with gcloud"

# Set project
log_info "Setting GCP project to ${PROJECT_ID}..."
gcloud config set project "${PROJECT_ID}" --quiet

# ============================================================================
# Run Tests
# ============================================================================

if [ "$SKIP_TESTS" = false ]; then
    log_info "Running tests... (use --skip-tests to skip)"

    # Clean previous test artifacts
    log_info "Cleaning test artifacts..."
    bash test/clean-test-artifacts.sh || true

    # Run unit and widget tests (excluding integration test directory)
    log_info "Running unit and widget tests..."
    flutter test test/models/ test/services/ test/widget_test.dart || {
        log_error "Unit/widget tests failed. Fix tests before deploying."
        exit 1
    }
    log_success "Unit and widget tests passed"

    # Run E2E widget tests
    log_info "Running E2E widget tests..."
    flutter test test/e2e_widget/ || {
        log_error "E2E widget tests failed. Fix tests before deploying."
        exit 1
    }
    log_success "E2E widget tests passed"

    # Note: Skipping Playwright E2E tests in local deploy (CI will run them)
    # They require the build to be complete first
    log_warning "Skipping browser E2E tests (will run in CI after deployment)"
else
    log_warning "Skipping tests (--skip-tests flag used)"
fi

# ============================================================================
# Build Flutter Web App
# ============================================================================

log_info "Building Flutter web app..."
flutter clean
flutter pub get
flutter build web --release || {
    log_error "Flutter build failed"
    exit 1
}
log_success "Flutter web app built successfully"

# ============================================================================
# Build Docker Image
# ============================================================================

log_info "Building Docker image..."
docker build --platform linux/amd64 -f scripts/Dockerfile -t "${IMAGE_NAME}:latest" -t "${IMAGE_NAME}:$(date +%Y%m%d-%H%M%S)" . || {
    log_error "Docker build failed"
    exit 1
}
log_success "Docker image built successfully"

# Optional: Test the Docker image locally
if command -v docker &> /dev/null && [ -z "${CI:-}" ]; then
    log_info "Testing Docker image locally (press Ctrl+C to skip)..."
    log_info "Visit http://localhost:8080 to verify the build"

    # Clean up any existing test container
    docker rm -f artist-finance-test 2>/dev/null || true

    # Run container in background
    docker run -d --name artist-finance-test -p 8080:8080 "${IMAGE_NAME}:latest" || {
        log_warning "Could not start test container (port might be in use)"
    }

    # Wait a bit for the container to start
    sleep 2

    # Try to hit the health endpoint
    if curl -f http://localhost:8080/health &> /dev/null; then
        log_success "Docker image is running correctly!"
        log_info "Test it at: http://localhost:8080"

        read -p "Press Enter to continue with deployment (or Ctrl+C to abort)..." || true
    else
        log_warning "Could not verify Docker container health"
    fi

    # Clean up test container
    docker rm -f artist-finance-test 2>/dev/null || true
fi

# ============================================================================
# Push Docker Image to Container Registry
# ============================================================================

log_info "Pushing Docker image to Google Container Registry..."
docker push "${IMAGE_NAME}:latest" || {
    log_error "Failed to push Docker image. Check your permissions."
    exit 1
}
log_success "Docker image pushed successfully"

# ============================================================================
# Deploy to Cloud Run
# ============================================================================

log_info "Deploying to Cloud Run..."
gcloud run deploy "${SERVICE_NAME}" \
    --image "${IMAGE_NAME}:latest" \
    --platform managed \
    --region "${REGION}" \
    --allow-unauthenticated \
    --port 8080 \
    --memory 512Mi \
    --cpu 1 \
    --min-instances 0 \
    --max-instances 10 \
    --timeout 300 \
    --set-env-vars "FLUTTER_WEB_APP=true" \
    --quiet || {
    log_error "Cloud Run deployment failed"
    exit 1
}

log_success "Deployment completed successfully!"

# ============================================================================
# Get Service URL and Test
# ============================================================================

SERVICE_URL=$(gcloud run services describe "${SERVICE_NAME}" \
    --region="${REGION}" \
    --format="value(status.url)")

log_success "Service deployed at: ${SERVICE_URL}"

# Health check
log_info "Running health check..."
if curl -f -s -o /dev/null -w "%{http_code}" "${SERVICE_URL}/health" | grep -q "200"; then
    log_success "Health check passed!"
    echo ""
    echo "=========================================="
    echo "  Deployment Successful!"
    echo "=========================================="
    echo "  URL: ${SERVICE_URL}"
    echo "=========================================="
else
    log_error "Health check failed. The app may not be working correctly."
    echo "  URL: ${SERVICE_URL}"
    echo "  Check logs: gcloud run services logs read ${SERVICE_NAME}"
    exit 1
fi

# ============================================================================
# Display Post-Deployment Information
# ============================================================================

echo ""
log_info "Useful commands:"
echo "  View logs:        gcloud run services logs read ${SERVICE_NAME} --region=${REGION}"
echo "  View service:     gcloud run services describe ${SERVICE_NAME} --region=${REGION}"
echo "  List revisions:   gcloud run revisions list --service=${SERVICE_NAME} --region=${REGION}"
echo "  Rollback:         ./scripts/rollback.sh <REVISION_NAME>"
echo ""

log_success "All done! Your app is now live at ${SERVICE_URL}"
