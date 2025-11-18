# Contributing to Frame TV Art Updater

## Local Development

### Prerequisites
- Docker and Docker Compose
- Git

### Quick Start

1. **Clone the repository**
   ```bash
   git clone <your-repo>
   cd FrameTVArt
   ```

2. **Create environment file**
   ```bash
   cp .env.example .env
   # Edit .env with your TV IP and settings
   ```

3. **Create local directories**
   ```bash
   mkdir -p images data
   # Add some test images to ./images/
   ```

4. **Build and run**
   ```bash
   docker-compose up --build
   ```

### Testing Changes

**Build locally:**
```bash
docker build -t frame-tv-art-updater:test .
```

**Run with custom args:**
```bash
docker run --rm \
  -e TV_IP=192.168.1.50 \
  -e UPDATE_INTERVAL=1 \
  -e DEBUG=1 \
  -v ./images:/art:ro \
  -v ./data:/app/samsung-tv-ws-api/example \
  frame-tv-art-updater:test
```

**Test entrypoint validation:**
```bash
# Should fail with validation error
docker run --rm -e TV_IP=invalid frame-tv-art-updater:test
```

### Dockerfile Changes

The Dockerfile uses multi-stage builds:
- **Builder stage**: Clones upstream repo
- **Runtime stage**: Minimal image with non-root user

Build args available:
- `UPSTREAM_REPO`: URL of samsung-tv-ws-api repo (default: official)
- `UPSTREAM_VERSION`: Branch/tag to clone (default: master)

```bash
docker build \
  --build-arg UPSTREAM_VERSION=some-branch \
  -t frame-tv-art-updater:custom .
```

### Entrypoint Changes

The `entrypoint.sh` script:
- Validates environment variables
- Maps env vars to upstream script CLI flags
- Handles signals for graceful shutdown

Test validation logic:
```bash
docker run --rm \
  -e TV_IP=192.168.1.50 \
  -e UPDATE_INTERVAL=not-a-number \
  frame-tv-art-updater:test
# Should exit with validation error
```

### Kubernetes Testing

Apply to test cluster:
```bash
# Update ConfigMap with your TV IP first
kubectl apply -f k8s/deployment.yaml
```

Check logs:
```bash
kubectl logs -n frame-tv-art -l app=frame-tv-art-updater -f
```

### CI/CD

GitHub Actions workflow runs on:
- Push to `main` → builds and pushes image
- Tags matching `v*` → builds with version tag
- Pull requests → builds only (no push)

The workflow includes:
- Multi-arch builds (amd64, arm64)
- Trivy security scanning
- Smoke tests verifying file structure

## Pull Request Guidelines

1. Test locally with `docker-compose up --build`
2. Ensure validation works for invalid inputs
3. Update README if adding new env vars
4. Update `.env.example` with new variables
5. Update K8s manifests if needed

## Architecture Notes

- **Persistence**: Token and `uploaded_files.json` stored in `/app/samsung-tv-ws-api/example`
- **User**: Runs as non-root user `appuser` (UID 1000)
- **Volumes**: `/art` (images), `/app/samsung-tv-ws-api/example` (state)
- **Health**: Process check via `pgrep`

## Upstream Dependency

This project wraps https://github.com/NickWaterton/samsung-tv-ws-api

Changes to upstream may require:
- Updating build args
- Adjusting script path in entrypoint
- Adding new environment variable mappings
