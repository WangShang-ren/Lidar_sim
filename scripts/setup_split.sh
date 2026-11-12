#!/usr/bin/env bash
# Source the split meta-workspace environments in dependency order.
set +u
unset AMENT_CURRENT_PREFIX COLCON_CURRENT_PREFIX
source /opt/ros/humble/setup.bash
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT/envs/livox_mid360s/install/setup.bash"
source "$ROOT/envs/fastlio/install/setup.bash"
source "$ROOT/envs/pointlio/install/setup.bash"
source "$ROOT/envs/sim_tools/install/setup.bash"
source "$ROOT/envs/nav_2026/install/setup.bash"
source "$ROOT/envs/rqt_ui/install/setup.bash"
