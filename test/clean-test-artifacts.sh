#!/bin/bash
# Script to clean up all test artifacts and temporary folders
# Run from test/ directory: ./clean-test-artifacts.sh
# Or from project root: ./test/clean-test-artifacts.sh

echo "🧹 Cleaning test artifacts..."

# Determine the project root (one level up from this script)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_ROOT" || exit 1

# Clean Flutter test artifacts
echo "  - Removing Flutter test results..."
rm -rf .tmp/
rm -rf test-results/
rm -rf test/results/
rm -rf test/integration_test/results/
rm -rf screenshots/
rm -f *.mp4
rm -f *.webm

# Clean Flutter coverage
echo "  - Removing coverage reports..."
rm -rf coverage/

# Clean E2E test artifacts
echo "  - Removing E2E test results..."
rm -rf test/e2e_web/test-results/
rm -rf test/e2e_web/playwright-report/
rm -rf test/e2e_web/.cache/

# Clean Flutter build artifacts
echo "  - Removing build artifacts..."
rm -rf build/

# Clean temporary server PID files
rm -f build/server.pid

echo "✅ Test artifacts cleaned successfully!"
echo ""
echo "To reinstall dependencies after cleaning:"
echo "  flutter pub get"
echo "  cd test/e2e_web && npm install"
