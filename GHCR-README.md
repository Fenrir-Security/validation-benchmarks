# GitHub Container Registry (GHCR) Integration

This repository now supports building and pushing Docker images to GitHub Container Registry (GHCR) for faster testing and CI/CD workflows.

## Overview

The GitHub Actions workflow automatically:
1. Builds all 104 benchmark containers
2. Tags them appropriately for GHCR
3. Pushes them to `ghcr.io/fenrir-security/validation-benchmarks`

## Using Pre-built Images

### Option 1: Automatic with Make (Recommended)
```bash
# Run a benchmark using GHCR images when available, fall back to building locally
BENCHMARK=XBEN-001-24 make run-ghcr
```

### Option 2: Generate Override Files
```bash
# Generate docker-compose.ghcr.yml override files for all benchmarks
./generate-ghcr-overrides.sh

# Then run with override
cd benchmarks/XBEN-001-24
docker-compose -f docker-compose.yml -f docker-compose.ghcr.yml up
```

### Option 3: Manual Docker Commands
```bash
# Pull specific images manually
docker pull ghcr.io/fenrir-security/validation-benchmarks/xben-001-24-db:latest
docker pull ghcr.io/fenrir-security/validation-benchmarks/xben-001-24-idor_broken_authz_trading_platform:latest
```

## Image Naming Convention

Images are tagged using the following pattern:
```
ghcr.io/fenrir-security/validation-benchmarks/{benchmark-name}-{service-name}:latest
```

Examples:
- `ghcr.io/fenrir-security/validation-benchmarks/xben-001-24-db:latest`
- `ghcr.io/fenrir-security/validation-benchmarks/xben-001-24-idor_broken_authz_trading_platform:latest`
- `ghcr.io/fenrir-security/validation-benchmarks/xben-004-24-web:latest`

## Environment Variables

- `USE_GHCR=1` (default): Enable GHCR image pulling in common.mk
- `USE_GHCR=0`: Disable GHCR and always build locally
- `NO_CACHE=1`: Build without Docker cache (affects both local and GHCR builds)

## GitHub Actions Workflow

The workflow is triggered on:
- Push to main/master branches
- Pull requests to main/master branches  
- Manual workflow dispatch

The workflow uses a matrix strategy to build all benchmarks in parallel with a max concurrency of 5 to avoid resource exhaustion.

## Troubleshooting

### Images not found in GHCR
If images aren't available in GHCR, the system will automatically fall back to building locally.

### Authentication issues
Make sure you have proper permissions to pull from the repository's packages. For public repositories, no authentication should be required.

### Build failures
Individual benchmark build failures won't stop the entire workflow due to `fail-fast: false` configuration.

## Benefits

1. **Faster CI/CD**: Skip building images that are already available
2. **Consistent environments**: Use the same pre-built images across different environments
3. **Reduced resource usage**: Less CPU and disk I/O during testing
4. **Parallel development**: Multiple developers can use the same base images