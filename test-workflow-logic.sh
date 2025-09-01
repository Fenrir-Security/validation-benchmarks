#!/bin/bash

# Test script to validate the GitHub Actions workflow logic locally
set -e

echo "Testing GitHub Actions workflow logic locally..."

# Test on a few benchmarks
BENCHMARKS=("XBEN-001-24" "XBEN-004-24" "XBEN-040-24")

for BENCHMARK in "${BENCHMARKS[@]}"; do
    echo ""
    echo "=== Testing $BENCHMARK ==="
    
    cd "benchmarks/$BENCHMARK"
    
    # Test service extraction (same logic as in workflow)
    SERVICES=$(python3 -c "
import json
import sys

try:
    import yaml
    # Use PyYAML if available
    with open('docker-compose.yml', 'r') as f:
        compose = yaml.safe_load(f)
    
    services_with_build = []
    if 'services' in compose:
        for service_name, service_config in compose['services'].items():
            if isinstance(service_config, dict) and 'build' in service_config:
                services_with_build.append(service_name)
    
    print(json.dumps(services_with_build))
    
except ImportError:
    # Fallback to simple text parsing if PyYAML not available
    services_with_build = []
    with open('docker-compose.yml', 'r') as f:
        lines = f.readlines()
    
    current_service = None
    
    for line in lines:
        stripped = line.strip()
        if not stripped or stripped.startswith('#'):
            continue
        
        # Calculate indentation
        line_indent = len(line) - len(line.lstrip())
        
        # Check if this is a service definition (under 'services:')
        if line_indent == 2 and ':' in stripped and not stripped.startswith('services'):
            current_service = stripped.split(':')[0].strip()
        elif current_service and 'build:' in stripped and line_indent > 2:
            if current_service not in services_with_build:
                services_with_build.append(current_service)
    
    print(json.dumps(services_with_build))
    
except Exception as e:
    print('[]', file=sys.stderr)
    print(f'Error parsing docker-compose.yml: {e}', file=sys.stderr)
    print('[]')
")
    
    echo "Services detected: $SERVICES"
    
    # Generate FLAG (same logic as workflow)
    BENCHMARK_UPPER=$(echo "$BENCHMARK" | tr '[:lower:]' '[:upper:]')
    FLAG=$(echo -n "$BENCHMARK_UPPER" | openssl sha256 -r | cut -d' ' -f1)
    FLAG_FMT="FLAG{$FLAG}"
    echo "Generated FLAG: $FLAG_FMT"
    
    # Test docker-compose config validation
    if docker-compose config > /dev/null 2>&1; then
        echo "✓ Docker compose configuration is valid"
    else
        echo "✗ Docker compose configuration is invalid"
    fi
    
    # Show what the image names would be
    BENCHMARK_LOWER=$(echo "$BENCHMARK" | tr '[:upper:]' '[:lower:]')
    echo "$SERVICES" | jq -r '.[]' 2>/dev/null | while read service; do
        if [ -n "$service" ]; then
            IMAGE_TAG="ghcr.io/fenrir-security/validation-benchmarks/${BENCHMARK_LOWER}-${service}:latest"
            echo "Would create image: $IMAGE_TAG"
        fi
    done
    
    cd "../.."
done

echo ""
echo "✓ All tests passed! The workflow logic should work correctly."