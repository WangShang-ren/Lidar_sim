#!/usr/bin/env bash
# Rebuild every split environment in dependency order.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENVS=(livox_mid360s fastlio pointlio sim_tools nav_2026 rqt_ui)

source /opt/ros/humble/setup.bash

for idx in "${!ENVS[@]}"; do
  ws="${ENVS[$idx]}"
  echo
  echo "============================================================"
  echo "Building $ws"
  echo "============================================================"

  # Source only the environments that have already been built.
  set +u
  source /opt/ros/humble/setup.bash
  for prev in "${ENVS[@]:0:$idx}"; do
    if [[ -f "$ROOT/envs/$prev/install/setup.bash" ]]; then
      source "$ROOT/envs/$prev/install/setup.bash"
    fi
  done
  set -u

  (
    cd "$ROOT/envs/$ws"
    colcon build --symlink-install --event-handlers console_direct+
  )
done

echo
echo "所有环境编译完成。"
echo "加载环境: source $ROOT/scripts/setup_split.sh"
