#!/usr/bin/env bash
# Helper script for using nerdctl with lima
# Usage: ./nerdctl.sh [nerdctl commands]

set -e

SOCKET="/run/user/501/containerd/containerd.sock"

if ! command -v limactl &> /dev/null; then
    echo "Error: limactl not found. Install lima first." >&2
    exit 1
fi

# Check if lima default instance is running
if ! limactl list | grep -q "default.*Running"; then
    echo "Starting lima default instance..."
    limactl start default
fi

# Pass all arguments to nerdctl in lima
exec limactl shell default nerdctl --address "$SOCKET" "$@"
