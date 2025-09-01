#!/bin/bash

# Test script to verify GHCR integration works
set -e

echo "Testing GHCR integration..."

# Test 1: Check if generate-ghcr-overrides.sh works
echo "Test 1: Generating GHCR override files"
./generate-ghcr-overrides.sh

# Test 2: Check if override files were created
echo "Test 2: Verifying override files were created"
if [ -f "benchmarks/XBEN-001-24/docker-compose.ghcr.yml" ]; then
    echo "✓ Override file created successfully"
else
    echo "✗ Override file not found"
    exit 1
fi

# Test 3: Validate docker-compose syntax
echo "Test 3: Validating docker-compose syntax"
cd benchmarks/XBEN-001-24
if docker compose -f docker-compose.yml -f docker-compose.ghcr.yml config > /dev/null; then
    echo "✓ Docker compose configuration is valid"
else
    echo "✗ Docker compose configuration is invalid"
    exit 1
fi

cd ../..

echo "✓ All tests passed! GHCR integration is ready to use."
echo ""
echo "Next steps:"
echo "1. Push this code to trigger the GitHub Actions workflow"
echo "2. Once images are built, test with: BENCHMARK=XBEN-001-24 make run-ghcr"
echo "3. The system will automatically pull from GHCR or build locally as needed"