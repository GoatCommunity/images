# Goat Images

Docker image factory for GoatOS container profiles.
Published at **`ghcr.io/goatcommunity/goat`**.

## Profiles

| Profile | Tag | Description |
|---------|-----|-------------|
| `full`  | `ghcr.io/goatcommunity/goat:full`  | Complete pentest toolkit (metasploit, impacket, netexec, bloodhound, john/hashcat, Go tools) |
| `light` | `ghcr.io/goatcommunity/goat:light` | Minimal daily-use container (nmap, netcat, dnsutils, httpie) |
| `recon` | `ghcr.io/goatcommunity/goat:recon` | Recon/web enumeration (ffuf, httpx, subfinder, nuclei, gobuster, feroxbuster) |

## Using the images

### Via the goat wrapper (recommended)

```bash
# Pull an image from the registry
goat install light

# Build an image locally
goat build recon

# Run a container
goat run lab01 --profile recon
```

### Direct docker pull

```bash
docker pull ghcr.io/goatcommunity/goat:light
docker tag  ghcr.io/goatcommunity/goat:light goat:light
```

## Building locally

```bash
# Build all profiles
./build-all.sh

# Build a specific profile
./build-all.sh recon

# Build and push to GHCR (requires docker login ghcr.io)
./build-all.sh --push
./build-all.sh recon --push
```

## Layout

```
sources/
  install/
    entrypoint.sh       # build dispatcher
    common.sh           # shared helpers (fapt, colorecho, register_tool, go_install)
    package_base.sh     # base system + Go + Python + shell setup
    package_desktop.sh  # XFCE + TigerVNC + noVNC
    package_light.sh    # light profile tools
    package_recon.sh    # recon profile + Go tools + wordlists
    package_pentest.sh  # AD/web/cracking/exploitation tools
    package_full.sh     # full profile (calls package_pentest)
  assets/
    goat/
      entrypoint.sh     # runtime entrypoint (container start/shell/desktop/VPN)
      spawn.sh          # shell spawner (shell selection, session logging)
    shells/
      zshrc             # zsh config with GOAT_NAME prompt
      tmux.conf         # tmux config
    desktop/            # XFCE configuration
```

## GitHub Actions

Images are automatically built and published to GHCR on every push to `main`.
See `.github/workflows/build.yml`.

## Compatibility with Exegol-images

The `goat-images` project follows the same Dockerfile pattern as Exegol-images:
- `LABEL org.goat.*` mirrors `LABEL org.exegol.*`
- Modular `package_*.sh` build steps
- `/.goat/entrypoint.sh` mirrors `/.exegol/entrypoint.sh`
- `GOAT_START_SHELL` mirrors `EXEGOL_START_SHELL`
- `GOAT_NAME` mirrors `EXEGOL_NAME`
