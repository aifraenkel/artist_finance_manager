#!/bin/bash

# This script retrieves Firebase web app configuration
# and updates lib/firebase_options.dart

PROJECT_ID=${GCP_PROJECT_ID:-"artist-manager-479514"}

echo "Getting Firebase web app configuration for project: $PROJECT_ID"
echo ""
echo "================================================"
echo "MANUAL STEPS REQUIRED:"
echo "================================================"
echo "1. Visit: https://console.firebase.google.com/project/$PROJECT_ID/settings/general"
echo "2. Scroll down to 'Your apps' section"
echo "3. If no web app exists, click 'Add app' and select 'Web'"
echo "4. Copy the firebaseConfig object values"
echo "5. Update lib/firebase_options.dart with the actual values"
echo ""
echo "The values you need to replace:"
echo "  - apiKey"
echo "  - appId"
echo "  - messagingSenderId (already set: 456648586026)"
echo "  - projectId (already set: $PROJECT_ID)"
echo "  - authDomain"
echo "  - storageBucket"
echo "  - measurementId"
echo ""
echo "Note: For development, you can also configure Firebase to work"
echo "with localhost by adding it to authorized domains in:"
echo "https://console.firebase.google.com/project/$PROJECT_ID/authentication/settings"
echo "================================================"
