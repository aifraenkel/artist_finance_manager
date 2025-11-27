#!/bin/bash

# Script to run E2E web tests against the Flutter web app
# This script builds the app, serves it, runs tests, and cleans up
# Run from test/e2e_web/ directory: ./run-e2e-tests.sh
# Or from project root: ./test/e2e_web/run-e2e-tests.sh

set -e

# Determine the project root (two levels up from this script)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"

cd "$PROJECT_ROOT" || exit 1

echo "🏗️  Building Flutter web app..."
flutter build web --release

echo "🚀 Starting web server on port 8000..."
cd build/web
python3 -m http.server 8000 > /dev/null 2>&1 &
SERVER_PID=$!
echo "   Server started (PID: $SERVER_PID)"

# Wait for server to be ready
echo "⏳ Waiting for server to be ready..."
sleep 3

# Go to e2e_web directory
cd "$PROJECT_ROOT/test/e2e_web" || exit 1

echo "🧪 Running Playwright E2E tests..."
npm test

# Capture test exit code
TEST_EXIT_CODE=$?

# Cleanup
echo "🧹 Stopping web server..."
kill $SERVER_PID 2>/dev/null || true

if [ $TEST_EXIT_CODE -eq 0 ]; then
  echo "✅ All E2E tests passed!"
else
  echo "❌ Some E2E tests failed. Check the report above."
fi

exit $TEST_EXIT_CODE
