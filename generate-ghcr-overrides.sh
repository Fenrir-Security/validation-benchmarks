#!/bin/bash

# Script to generate docker-compose.ghcr.yml override files for using GHCR images
# This script will scan all benchmarks and create override files that use pre-built images from GHCR

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BENCHMARKS_DIR="$SCRIPT_DIR/benchmarks"
GHCR_REGISTRY="ghcr.io/fenrir-security/validation-benchmarks"

echo "Generating GHCR override files for all benchmarks..."

if [ ! -d "$BENCHMARKS_DIR" ]; then
    echo "Error: benchmarks directory not found at $BENCHMARKS_DIR"
    exit 1
fi

for benchmark_dir in "$BENCHMARKS_DIR"/XBEN-*-24; do
    if [ ! -d "$benchmark_dir" ]; then
        continue
    fi
    
    benchmark=$(basename "$benchmark_dir")
    benchmark_lower=$(echo "$benchmark" | tr '[:upper:]' '[:lower:]')
    
    echo "Processing $benchmark..."
    
    docker_compose_file="$benchmark_dir/docker-compose.yml"
    override_file="$benchmark_dir/docker-compose.ghcr.yml"
    
    if [ ! -f "$docker_compose_file" ]; then
        echo "  Warning: No docker-compose.yml found, skipping"
        continue
    fi
    
    # Extract services that have build directives
    cd "$benchmark_dir"
    services_with_build=$(docker compose config --services 2>/dev/null | while read service; do
        if docker compose config 2>/dev/null | grep -A 10 "^  $service:" | grep -q "build:"; then
            echo "$service"
        fi
    done)
    
    if [ -z "$services_with_build" ]; then
        echo "  No services with build directives found, skipping"
        continue
    fi
    
    # Generate override file
    cat > "$override_file" << EOF
# Auto-generated override file for using GHCR pre-built images
# Use with: docker-compose -f docker-compose.yml -f docker-compose.ghcr.yml up
services:
EOF
    
    echo "$services_with_build" | while read service; do
        if [ -n "$service" ]; then
            image_tag="$GHCR_REGISTRY/$benchmark_lower-$service:latest"
            cat >> "$override_file" << EOF
  $service:
    image: $image_tag
    build: null  # Override build directive
EOF
        fi
    done
    
    echo "  Generated $override_file"
done

echo "Done! You can now use GHCR images by running:"
echo "  BENCHMARK=XBEN-001-24 make run-ghcr"
echo ""
echo "Or manually with:"
echo "  cd benchmarks/XBEN-001-24"
echo "  docker compose -f docker-compose.yml -f docker-compose.ghcr.yml up"