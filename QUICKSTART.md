# Frame TV Art Updater - Quick Start

## Docker Compose (Recommended for Local Use)

1. **Setup:**
   ```bash
   cp .env.example .env
   # Edit .env with your TV IP
   # Ensure FRAME_TV_TLS_HOSTNAME matches the certificate (default SmartViewSDK)
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
   -e FRAME_TV_TLS_HOSTNAME=SmartViewSDK \
  -e UPDATE_INTERVAL=1440 \
  -e CHECK_INTERVAL=60 \
  -v /path/to/images:/art:ro \
   -v /path/to/data:/data \
   --add-host SmartViewSDK:192.168.1.50 \
  ghcr.io/<owner>/frame-tv-art-updater:latest
```

## Kubernetes

```bash
# Edit k8s/deployment.yaml first (update TV_IP in ConfigMap and hostAliases)
kubectl apply -f k8s/deployment.yaml

# Check status
kubectl get pods -n media
kubectl logs -n media -l app=frame-tv-art-updater -f
```

> Pods run as UID/GID `1000` and rely on the pod-level `fsGroup: 1000` security context configured in `k8s/deployment.yaml` so `/data` stays writable. If you trim the manifest, be sure your volume allows UID/GID `1000` or adjust `TOKEN_FILE` to a writable path.

## TLS Requirements

- The Frame TV certificate is issued to `SmartViewSDK`. Keep `FRAME_TV_TLS_HOSTNAME` aligned with the CN and map it to `TV_IP`.
- The base image already trusts `certs/frame-tv-smartviewsdk.pem`. Override `FRAME_TV_CERT_PATH` only if you have a custom certificate bundle.
- Compose already sets `extra_hosts` based on your env file. For `docker run`, pass `--add-host <hostname>:<TV_IP>` (see example above).
- Kubernetes users must update `hostAliases` in `k8s/deployment.yaml` so `<hostname>` resolves to the TV IP inside the pod (use lowercase values to satisfy RFC 1123, e.g., `smartviewsdk`).
- If you must bypass verification temporarily, set `FRAME_TV_TLS_VERIFY=0`, but re-enable it once connectivity issues are resolved.

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

Mount `/data` to preserve:
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
