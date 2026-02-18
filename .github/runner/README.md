# Dockerized GitHub Actions Runner

This folder runs a self-hosted GitHub Actions runner container for FPGA bitstream generation.

Finalized method: **use host Vivado installation (`/opt/Xilinx`) mounted into the container**.

**Note**: The runner uses Ubuntu 22.04 (not 24.04) because Vivado 2025.2's license manager has compatibility issues with Ubuntu 24.04's libudev library, causing crashes during synthesis runs.

## Runner usage in CI

- `simulation` job runs on GitHub-hosted `ubuntu-24.04`
- `build-bitstream` job runs on labels: `self-hosted, linux, xilinx`

This runner is only used by the bitstream build job.

## Requirements

- Host machine already has Vivado installed at `/opt/Xilinx`.
- Docker engine is installed and running.
- Docker Compose **v2 plugin** is installed (`docker compose version`).
- Legacy `docker-compose` v1 is **not supported** for this runner stack.
- Runner can access GitHub and your repository.

## Setting up the runner

### 1) Create runner token

`GH_RUNNER_TOKEN` is a short-lived **registration token** (not a personal access token).

#### Option A: GitHub UI

In GitHub:
- Repository → `Settings` → `Actions` → `Runners` → `New self-hosted runner`
- Copy the registration token

#### Option B: GitHub CLI (`gh`)

**Prerequisites**: Ensure `gh` CLI is authenticated with `admin:org` scope:

```bash
# Check current authentication status
gh auth status

# If needed, refresh authentication with required scope
gh auth refresh -s admin:org
```

Generate a fresh token from your terminal:

```bash
gh api \
	-X POST \
	repos/<owner>/<repo>/actions/runners/registration-token \
	--jq .token
```

For this repository:

```bash
gh api \
	-X POST \
	repos/yansyaf/fpga-template-blinky/actions/runners/registration-token \
	--jq .token
```

Use the output value as `GH_RUNNER_TOKEN`.

### 2) Configure environment file

```bash
cd .github/runner
cp .env.example .env
```

Edit `.env`:
- `GH_RUNNER_URL` = your repo URL
- `GH_RUNNER_TOKEN` = registration token
- `GH_BITSTREAM_RUNNER_IMAGE` = runner image tag
- `GH_BITSTREAM_RUNNER_XILINX_HOST_DIR` = host Xilinx path (default `/opt/Xilinx`)

### 3) Build local runner image

```bash
cd .github/runner
docker build -t ghcr.io/<owner>/fpga-bitstream-runner:latest .
```

### 4) Start runner

```bash
docker compose up -d
```

`docker-compose.yml` includes a local `build` section, so Compose can build the image from this folder when needed.
After Docker cache/image cleanup, use:

```bash
docker compose up -d --build
```

### 5) Verify

- In GitHub runner settings, runner should show `Online`.
- Workflow jobs with label `xilinx` go to `bitstream-runner`.
- Validate Vivado inside container:

```bash
docker exec -it fpga-gha-bitstream-runner bash -lc 'which vivado && vivado -version'
```

## View runner logs

To see runner container logs in real-time:

```bash
docker compose logs -f bitstream-runner
```

To view recent logs without following:

```bash
docker compose logs --tail=100 bitstream-runner
```

To check runner status:

```bash
docker compose ps
```

## Stop / remove the runner

```bash
docker compose down
```

The container unregisters itself on shutdown.

## Notes

- This runner image does **not** install Vivado during build.
- Vivado binaries are provided at runtime by mounting host `/opt/Xilinx` into the container.
- Keep `.env` private; `GH_RUNNER_TOKEN` expires and must be refreshed when needed.

## Troubleshooting

- `Http response code: NotFound ... /actions/runner-registration`:
	- Usually `GH_RUNNER_TOKEN` is expired/invalid. Generate a fresh registration token and update `.env` (See generate a fresh token from your terminal)
	- Verify `GH_RUNNER_URL` is exactly `https://github.com/<owner>/<repo>`.
