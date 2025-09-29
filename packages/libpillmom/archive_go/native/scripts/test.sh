#!/bin/bash

# Go to native directory (parent of scripts)
cd "$(dirname "$0")/.."

# Load environment variables from .env file
if [ -f .env ]; then
    export $(grep -v '^#' .env | xargs)
    echo "✓ Loaded environment variables from .env"
fi

# Ensure CGO is enabled for go-libsql
export CGO_ENABLED=1

echo "Running database tests with go-libsql..."
echo ""

# Run tests
go test ./database -v 2>&1 | grep -v "ld: warning"

echo ""
echo "Test completed!"