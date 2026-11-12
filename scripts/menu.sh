#!/usr/bin/env bash
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
while true; do
  echo
  echo "=== COD RMUL 2026 Meta Workspace ==="
  echo "1. 启动真实雷达 + RViz"
  echo "2. 启动 FAST-LIO 2026 仿真"
  echo "3. 启动 Point-LIO 2026 仿真"
  echo "4. LIO 调参 CLI"
  echo "5. LIO Tuner GUI"
  echo "0. 退出"
  read -r -p "选择: " c
  case "$c" in
    1) "$DIR/scripts/run_lidar.sh" ;;
    2) "$DIR/scripts/run_fastlio_2026.sh" ;;
    3) "$DIR/scripts/run_pointlio_2026.sh" ;;
    4) "$DIR/scripts/run_lio_tune.sh" ;;
    5) "$DIR/scripts/run_lio_tune_gui.sh" ;;
    0) exit 0 ;;
    *) echo "无效选择" ;;
  esac
done
