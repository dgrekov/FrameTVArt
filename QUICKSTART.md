# Frame TV Art Updater - Quick Start

## Docker Compose (Recommended for Local Use)

1. **Setup:**
   ```bash
   cp .env.example .env
   # Edit .env with your TV IP
   mkdir -p images data
   # Copy images to ./images/
   ```

2. **Run:**
   ```bash
   docker-compose up -d
   ```

3. **View logs:**
   ```bash
   docker-compose logs -f
   ```

## Docker Run

```bash
docker run -d \
  --name frame-tv-art \
  --restart unless-stopped \
  -e TV_IP=192.168.1.50 \
  -e UPDATE_INTERVAL=1440 \
  -e CHECK_INTERVAL=60 \
  -v /path/to/images:/art:ro \
  -v /path/to/data:/app/samsung-tv-ws-api/example \
  ghcr.io/<owner>/frame-tv-art-updater:latest
```

## Kubernetes

```bash
# Edit k8s/deployment.yaml first (update TV_IP in ConfigMap)
kubectl apply -f k8s/deployment.yaml

# Check status
kubectl get pods -n frame-tv-art
kubectl logs -n frame-tv-art -l app=frame-tv-art-updater -f
```

## Common Configurations

### Daily Art Change (One Image)
```env
UPDATE_INTERVAL=0
CHECK_INTERVAL=0
```
Run via cron: `docker-compose up` once per day

### Slideshow (Random, Every Hour)
```env
UPDATE_INTERVAL=60
CHECK_INTERVAL=60
SEQUENTIAL=0
```

### Sequential Slideshow (Every 5 Minutes)
```env
UPDATE_INTERVAL=5
CHECK_INTERVAL=300
SEQUENTIAL=1
```

### Include TV Favourites in Rotation
```env
UPDATE_INTERVAL=1440
INCLUDE_FAVOURITES=1
```

## Persistence

Mount `/app/samsung-tv-ws-api/example` to preserve:
- `token_file.txt` (TV pairing token)
- `uploaded_files.json` (tracking uploaded art)

Without this volume, you'll need to re-pair and re-upload on every restart.

## Troubleshooting

**Enable debug logging:**
```env
DEBUG=1
```

**Test TV connectivity:**
```bash
docker-compose exec frame-tv-art-updater sh -c 'ping -c 3 $TV_IP'
```

**Check script is running:**
```bash
docker-compose exec frame-tv-art-updater ps aux
```

**Manual script invocation:**
```bash
docker-compose exec frame-tv-art-updater python \
  /app/samsung-tv-ws-api/example/async_art_update_from_directory.py \
  192.168.1.50 -f /art -u 0 -c 0 -D
```
