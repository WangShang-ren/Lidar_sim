#!/usr/bin/env bash
set -e
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
exec "$DIR/envs/livox_mid360s/run_mid360s_rviz.sh" "$@"
