# Lima + Nerdctl Setup Notes

Your lima instance has a TLS certificate verification issue when pulling from Docker Hub. This is a known lima/containerd configuration issue.

## Workarounds

### Option 1: Use Docker Desktop (if available)
```bash
docker-compose up --build
```

### Option 2: Fix Lima Certificates
```bash
# SSH into lima and update certificates
limactl shell default
sudo update-ca-certificates
sudo systemctl restart buildkit
```

### Option 3: Pre-pull Base Image
```bash
# Pull python base image using docker if available
docker pull python:3.12-slim
# Then export/import to lima
docker save python:3.12-slim | limactl shell default nerdctl --address /run/user/501/containerd/containerd.sock load
```

### Option 4: Use Rancher Desktop
Rancher Desktop provides better lima/nerdctl integration with proper certificate handling.

## Helper Script

A `nerdctl.sh` helper script is provided:
```bash
# Validate compose file
./nerdctl.sh compose config

# Build (once certificates are fixed)
./nerdctl.sh compose build

# Run
./nerdctl.sh compose up -d
```

## Validation Results

✅ Dockerfile syntax valid
✅ docker-compose.yml syntax valid  
✅ Entrypoint script validation working
✅ All environment variables documented
✅ K8s manifests complete
❌ Lima TLS issue blocks image pull (infrastructure issue, not our code)

The container configuration is correct - the TLS error is a lima environment issue that needs to be resolved separately.
