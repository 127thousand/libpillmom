#!/bin/bash

# Go to native directory (parent of scripts)
cd "$(dirname "$0")/.."

echo "Cleaning up test artifacts..."

# Clean up test databases
rm -f database/*.db* 2>/dev/null
rm -f *.db* 2>/dev/null
rm -f examples/*.db* 2>/dev/null

# Clean up temporary test directories
rm -rf /tmp/libpillmom_test_* 2>/dev/null
rm -rf /tmp/libpillmom_sync_test_* 2>/dev/null
rm -rf /tmp/libpillmom_multi_test_* 2>/dev/null

# Clean up Go test cache
go clean -testcache 2>/dev/null

echo "✅ Cleanup complete"