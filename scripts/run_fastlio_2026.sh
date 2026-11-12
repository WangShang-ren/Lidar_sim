#!/usr/bin/env bash
set -e
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
exec "$DIR/envs/sim_tools/sim2026/run_sim_2026.sh" "$@"
