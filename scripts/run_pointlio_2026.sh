#!/usr/bin/env bash
set -e
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
exec "$DIR/envs/sim_tools/pointlio_sim/run_cod26_sim.sh" "$@"
