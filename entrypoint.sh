#!/usr/bin/env sh
set -e

# Signal handling for graceful shutdown
trap 'echo "Received shutdown signal, exiting..." >&2; exit 0' TERM INT

# Validation functions
validate_ip() {
    echo "$1" | grep -Eq '^([0-9]{1,3}\.){3}[0-9]{1,3}$' || return 1
}

validate_number() {
    echo "$1" | grep -Eq '^[0-9]+(\.[0-9]+)?$' || return 1
}

# Required variables
if [ -z "$TV_IP" ]; then
  echo "Error: TV_IP environment variable required." >&2
  exit 1
fi

if ! validate_ip "$TV_IP"; then
  echo "Warning: TV_IP='$TV_IP' does not look like a valid IP address" >&2
fi

# Core configuration with validation
ART_FOLDER="${ART_FOLDER:-/art}"
UPDATE_INTERVAL="${UPDATE_INTERVAL:-0}"            # minutes; 0 disables slideshow
CHECK_INTERVAL="${CHECK_INTERVAL:-60}"             # seconds; 0 runs once
MATTE="${MATTE:-none}"
TOKEN_FILE="${TOKEN_FILE:-/data/token_file.txt}"        # persistent token file path (host-mounted /data)
TOKEN_DIR="$(dirname "$TOKEN_FILE")"

if [ ! -d "$TOKEN_DIR" ]; then
  if ! mkdir -p "$TOKEN_DIR" 2>/dev/null; then
    echo "Error: unable to create token directory $TOKEN_DIR. Check volume permissions or adjust TOKEN_FILE." >&2
    echo "Hint: mount /data with write access for UID/GID 1000 or configure your Kubernetes fsGroup." >&2
    exit 1
  fi
fi

TOKEN_CHECK_FILE="$TOKEN_DIR/.token_write_test.$$"
if ! touch "$TOKEN_CHECK_FILE" 2>/dev/null; then
  echo "Error: token directory $TOKEN_DIR is not writable. Ensure your persistent volume allows UID/GID 1000." >&2
  echo "Hint: set fsGroup in Kubernetes or fix host volume permissions." >&2
  exit 1
fi
rm -f "$TOKEN_CHECK_FILE" 2>/dev/null || true

FRAME_TV_CERT_PATH="${FRAME_TV_CERT_PATH:-/usr/local/share/ca-certificates/frame-tv-smartviewsdk.crt}"
FRAME_TV_TLS_VERIFY="${FRAME_TV_TLS_VERIFY:-1}"
FRAME_TV_TLS_HOSTNAME="${FRAME_TV_TLS_HOSTNAME:-SmartViewSDK}"
export FRAME_TV_CERT_PATH FRAME_TV_TLS_VERIFY

TARGET_HOST="$TV_IP"
if [ -n "$FRAME_TV_TLS_HOSTNAME" ]; then
  TARGET_HOST="$FRAME_TV_TLS_HOSTNAME"
fi

# Validate numeric values
if ! validate_number "$UPDATE_INTERVAL"; then
    echo "Error: UPDATE_INTERVAL must be numeric, got: $UPDATE_INTERVAL" >&2
    exit 1
fi

if ! validate_number "$CHECK_INTERVAL"; then
    echo "Error: CHECK_INTERVAL must be numeric, got: $CHECK_INTERVAL" >&2
    exit 1
fi

# Flags (boolean env vars -> presence of option)
[ "${INCLUDE_FAVOURITES}" = "1" ] && INCLUDE_F="-F" || INCLUDE_F=""
[ "${SEQUENTIAL}" = "1" ] && SEQUENTIAL_FLAG="-S" || SEQUENTIAL_FLAG=""
[ "${EXIT_IF_OFF}" = "1" ] && EXIT_IF_OFF_FLAG="-O" || EXIT_IF_OFF_FLAG=""
# SYNC: upstream uses -s to DISABLE sync; default enabled unless SYNC=0
if [ "${SYNC:-1}" = "0" ]; then SYNC_FLAG="-s"; else SYNC_FLAG=""; fi
[ "${DEBUG}" = "1" ] && DEBUG_FLAG="-D" || DEBUG_FLAG=""

if [ ! -d "$ART_FOLDER" ]; then
  mkdir -p "$ART_FOLDER" 2>/dev/null || echo "Warning: could not create folder $ART_FOLDER" >&2
fi

SCRIPT="/app/samsung-tv-ws-api/example/async_art_update_from_directory.py"
if [ ! -f "$SCRIPT" ]; then
  echo "Error: upstream script not found at $SCRIPT" >&2
  exit 2
fi

echo "Starting Frame TV Art Updater" >&2
echo "  TV IP: $TV_IP" >&2
echo "  Art Folder: $ART_FOLDER" >&2
echo "  Update Interval: ${UPDATE_INTERVAL}min, Check Interval: ${CHECK_INTERVAL}s" >&2
echo "  Matte: $MATTE, Sequential: ${SEQUENTIAL:-0}, Favourites: ${INCLUDE_FAVOURITES:-0}" >&2
echo "  Token file: $TOKEN_FILE" >&2
if [ "$TARGET_HOST" != "$TV_IP" ]; then
  echo "  TLS Hostname: $TARGET_HOST (maps to $TV_IP)" >&2
fi

echo "Running Command: python \"$SCRIPT\" \"$TARGET_HOST\" -f \"$ART_FOLDER\" -u \"$UPDATE_INTERVAL\" -c \"$CHECK_INTERVAL\" \
    -m \"$MATTE\" -t \"$TOKEN_FILE\" $INCLUDE_F $SEQUENTIAL_FLAG $EXIT_IF_OFF_FLAG $SYNC_FLAG $DEBUG_FLAG" >&2

exec python "$SCRIPT" "$TARGET_HOST" -f "$ART_FOLDER" -u "$UPDATE_INTERVAL" -c "$CHECK_INTERVAL" \
    -m "$MATTE" -t "$TOKEN_FILE" $INCLUDE_F $SEQUENTIAL_FLAG $EXIT_IF_OFF_FLAG $SYNC_FLAG $DEBUG_FLAG
