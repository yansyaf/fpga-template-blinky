#!/usr/bin/env bash
set -euo pipefail

: "${GH_RUNNER_URL:?GH_RUNNER_URL is required}"
: "${GH_RUNNER_TOKEN:?GH_RUNNER_TOKEN is required}"

GH_RUNNER_NAME="${GH_RUNNER_NAME:-docker-runner-$(hostname)}"
GH_RUNNER_LABELS="${GH_RUNNER_LABELS:-self-hosted,linux,xilinx}"
GH_RUNNER_WORKDIR="${GH_RUNNER_WORKDIR:-_work}"

if [[ "${GH_RUNNER_WORKDIR}" = /* ]]; then
  workdir_path="${GH_RUNNER_WORKDIR}"
else
  workdir_path="/home/runner/actions-runner/${GH_RUNNER_WORKDIR}"
fi

if [[ "$(id -u)" -eq 0 && -z "${RUNNER_BOOTSTRAPPED:-}" ]]; then
  mkdir -p "${workdir_path}" "${workdir_path}/_tool"
  chown -R runner:runner "${workdir_path}"

  export RUNNER_BOOTSTRAPPED=1
  exec sudo -H -u runner \
    --preserve-env=GH_RUNNER_URL,GH_RUNNER_TOKEN,GH_RUNNER_NAME,GH_RUNNER_LABELS,GH_RUNNER_WORKDIR,RUNNER_BOOTSTRAPPED \
    /entrypoint.sh
fi

echo "[preflight] runner user: $(id -un) (uid=$(id -u), gid=$(id -g))"
echo "[preflight] HOME: ${HOME}"
echo "[preflight] runner workdir: ${workdir_path}"
if [[ -e "${workdir_path}" ]]; then
  ls -ld "${workdir_path}"
else
  echo "[preflight] workdir does not exist yet"
fi
if [[ -e "${workdir_path}/_tool" ]]; then
  ls -ld "${workdir_path}/_tool"
else
  echo "[preflight] _tool cache directory does not exist yet"
fi

if [[ -d /opt/Xilinx ]]; then
  latest_vivado_bin="$(find /opt/Xilinx -maxdepth 4 -type d -path '*/Vivado/bin' | sort | tail -n 1 || true)"
  if [[ -n "${latest_vivado_bin}" ]]; then
    export PATH="${latest_vivado_bin}:${PATH}"
  fi
fi

# Vivado workarounds for containerized environment
export MALLOC_CHECK_=0
export MALLOC_PERTURB_=0
# Disable WebTalk to avoid license manager USB enumeration crashes
export AP_ENABLE_WEBTALK=0
export XILINXD_LICENSE_FILE=2100@localhost
if [[ -f /usr/lib/x86_64-linux-gnu/libudev.so.0 ]]; then
  export LD_PRELOAD="/usr/lib/x86_64-linux-gnu/libudev.so.0${LD_PRELOAD:+:${LD_PRELOAD}}"
fi

cleanup() {
  echo "Removing runner registration..."
  ./config.sh remove --token "${GH_RUNNER_TOKEN}" || true
}
trap cleanup EXIT INT TERM

if [[ -f .runner ]]; then
  ./config.sh remove --token "${GH_RUNNER_TOKEN}" || true
fi

./config.sh \
  --url "${GH_RUNNER_URL}" \
  --token "${GH_RUNNER_TOKEN}" \
  --name "${GH_RUNNER_NAME}" \
  --labels "${GH_RUNNER_LABELS}" \
  --work "${GH_RUNNER_WORKDIR}" \
  --replace

./run.sh
