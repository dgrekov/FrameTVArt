# Frame TV Art Updater Container

Containerized wrapper around [NickWaterton/samsung-tv-ws-api](https://github.com/NickWaterton/samsung-tv-ws-api) to periodically update art images on a Samsung Frame TV using the upstream async script `async_art_update_from_directory.py`.

## How It Works
- Image clones the upstream repo at build time.
- Installs dependencies from its `requirements.txt`.
- A lightweight shell `entrypoint.sh` reads environment variables and directly executes the upstream example script (no nested Python subprocess).

## Environment Variables
| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `TV_IP` | Yes | — | IP address of your Samsung Frame TV. |
| `ART_FOLDER` | No | `/art` | Directory (volume) containing images to cycle through. |
| `UPDATE_INTERVAL` | No | `0` | Slideshow update period in minutes (0 = disabled). |
| `CHECK_INTERVAL` | No | `60` | Seconds between folder scans (0 = run once then exit). |
| `MATTE` | No | `none` | Matte style applied to uploaded art (see upstream matte list). |
| `TOKEN_FILE` | No | `/data/token_file.txt` | Token file path stored in persistent volume (mount host `./data` to `/data`). |
| `INCLUDE_FAVOURITES` | No | `0` | Set to `1` to include TV favourites in rotation (`-F`). |
| `SEQUENTIAL` | No | `0` | Set to `1` for sequential slideshow (`-S`); random otherwise. |
| `EXIT_IF_OFF` | No | `0` | Set to `1` to exit if TV is off (`-O`). |
| `SYNC` | No | `1` | Set to `0` to disable initial PIL synchronization (`-s`). |
| `DEBUG` | No | `0` | Set to `1` to enable debug logging (`-D`). |

## Building Locally
```bash
docker build -t frame-tv-art-updater:local .
```

## Running
Mount (or copy) a folder of images into the container at the path specified by `ART_FOLDER` (default `/art`).
```bash
docker run --rm \
  -e TV_IP="<your_tv_ip>" \
  -e ART_FOLDER="/art" \
  -e UPDATE_INTERVAL=1440 \
  -e CHECK_INTERVAL=60 \
  -e SEQUENTIAL=1 \
  -v /path/to/images:/art:ro \
  frame-tv-art-updater:local
```

## GitHub Container Registry (GHCR)
A GitHub Actions workflow (`.github/workflows/build.yml`) builds and pushes multi-arch images on pushes to `main` and tags matching `v*`.
Image name pattern: `ghcr.io/<owner>/frame-tv-art-updater`.

## Customization
If you need additional Python dependencies not covered by upstream requirements, add them to `requirements.txt` and rebuild.

Pillow is installed in the image to enable automatic synchronization features (thumbnail matching). Remove it by editing the `Dockerfile` if not needed.

The upstream script stores `uploaded_files.json` and the token file in its own directory. To persist these across container restarts do NOT mount the upstream example directory directly — instead mount a small persistent directory to `/data` and set `TOKEN_FILE=/data/token_file.txt`:
```bash
docker run -v /host/config:/data ...
```

## License
This project wraps a public upstream repository. Review the upstream repository's license for usage terms.
