#!/bin/bash

# Master setup script - runs all setup steps in order
# This is a one-command setup for the entire Firebase authentication system

set -e

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }
info() { echo -e "${BLUE}[INFO]${NC} $1"; }
warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
section() { echo -e "${CYAN}[SECTION]${NC} $1"; }

PROJECT_ID=${GCP_PROJECT_ID:-"artist-manager-479514"}
REGION=${GCP_REGION:-"us-central1"}

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║     Artist Finance Manager - Complete Setup               ║"
echo "║     Firebase Authentication System                         ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
info "Project: $PROJECT_ID"
info "Region: $REGION"
echo ""

# Check if user wants to proceed
read -p "This will set up Firebase, Authentication, Firestore, and Cloud Functions. Continue? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    info "Setup cancelled"
    exit 0
fi

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check prerequisites
section "Checking prerequisites..."

MISSING_DEPS=0

if ! command_exists gcloud; then
    error "gcloud CLI not found. Please install: https://cloud.google.com/sdk/install"
    MISSING_DEPS=1
fi

if ! command_exists flutter; then
    error "Flutter not found. Please install: https://flutter.dev/docs/get-started/install"
    MISSING_DEPS=1
fi

if ! command_exists npm; then
    warning "npm not found. Cloud Functions deployment will be skipped."
fi

if [ $MISSING_DEPS -eq 1 ]; then
    error "Missing required dependencies. Please install them and try again."
    exit 1
fi

success "All prerequisites met"
echo ""

# Step 1: Complete Firebase setup
section "Step 1: Setting up Firebase infrastructure..."
if [ -x "./scripts/setup_firebase_complete.sh" ]; then
    ./scripts/setup_firebase_complete.sh
else
    chmod +x ./scripts/setup_firebase_complete.sh
    ./scripts/setup_firebase_complete.sh
fi
echo ""

# Step 2: Install Flutter dependencies
section "Step 2: Installing Flutter dependencies..."
flutter pub get
success "Flutter dependencies installed"
echo ""

# Step 3: Deploy Cloud Functions (optional)
section "Step 3: Deploying Cloud Functions..."
read -p "Do you want to deploy Cloud Functions for email notifications? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    if [ -x "./scripts/deploy_functions.sh" ]; then
        ./scripts/deploy_functions.sh
    else
        chmod +x ./scripts/deploy_functions.sh
        ./scripts/deploy_functions.sh
    fi
else
    info "Skipping Cloud Functions deployment"
fi
echo ""

# Step 4: Build and test
section "Step 4: Running tests and build check..."
info "Running Flutter analyzer..."
flutter analyze || warning "Some analysis issues found (see above)"
echo ""

info "Running unit tests..."
flutter test || warning "Some tests failed"
echo ""

# Step 5: Configuration summary
section "Setup Complete! 🎉"
echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║                    Setup Summary                           ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
success "✓ Firebase infrastructure configured"
success "✓ Authentication methods enabled"
success "✓ Firestore database and rules deployed"
success "✓ Transaction sync enabled for authenticated users"
success "✓ Flutter dependencies installed"
success "✓ Web app configuration updated"
echo ""

info "Next steps to complete setup:"
echo ""
echo "1. Verify Firebase Configuration:"
echo "   • Open: lib/firebase_options.dart"
echo "   • Ensure all values are populated (not placeholder values)"
echo ""
echo "2. Configure Firebase Console Settings:"
echo "   • Visit: https://console.firebase.google.com/project/$PROJECT_ID"
echo "   • Go to Authentication > Sign-in method"
echo "   • Verify Email/Password is enabled"
echo "   • Verify Email link (passwordless) is enabled"
echo "   • Go to Authentication > Settings"
echo "   • Add your Cloud Run domain to authorized domains"
echo ""
echo "3. Verify Firestore Rules (for data sync):"
echo "   • Visit: https://console.firebase.google.com/project/$PROJECT_ID/firestore/rules"
echo "   • Ensure rules allow users/{userId}/transactions subcollection access"
echo ""
echo "4. Test Locally:"
echo "   flutter run -d chrome"
echo "   # Try registering a new account"
echo "   # Add transactions and verify sync icon appears"
echo ""
echo "5. Deploy to Production:"
echo "   ./scripts/deploy.sh"
echo ""
echo "6. Optional - Email Service:"
echo "   • Sign up for SendGrid/Mailgun/AWS SES"
echo "   • Update functions/index.js with email integration"
echo "   • Redeploy functions: ./scripts/deploy_functions.sh"
echo ""

info "Documentation:"
echo "   • Setup guide: docs/AUTH_SETUP.md"
echo "   • Backend sync guide: docs/BACKEND_SYNC.md"
echo "   • Firebase console: https://console.firebase.google.com/project/$PROJECT_ID"
echo "   • GCP console: https://console.cloud.google.com/home/dashboard?project=$PROJECT_ID"
echo ""

success "All automated setup steps completed!"
echo ""

# Offer to open Firebase Console
read -p "Open Firebase Console in browser? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    if command_exists open; then
        open "https://console.firebase.google.com/project/$PROJECT_ID"
    elif command_exists xdg-open; then
        xdg-open "https://console.firebase.google.com/project/$PROJECT_ID"
    else
        info "Please open: https://console.firebase.google.com/project/$PROJECT_ID"
    fi
fi

exit 0
