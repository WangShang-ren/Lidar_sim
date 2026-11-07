#!/usr/bin/env python3
"""Small LIO parameter tuner for FAST-LIO and Point-LIO.

It edits the YAML used by the running LIO, restarts only the LIO node,
and waits for the node to come back.  It does not restart the lidar
driver, Gazebo, or Nav2.
"""

import argparse
import json
import os
import shutil
import signal
import subprocess
import sys
import time
from datetime import datetime
from pathlib import Path

import yaml

HOME = Path.home()
STATE_FILE = Path("/home/shaun/static/Mtools/lio_tune/last_state.json")
LOG_DIR = Path("/home/shaun/static/Mtools/lio_tune/logs")

FAST_SOURCE = Path("/home/shaun/static/tools/cod_ws/src/COD_NAV/FAST_LIO/FAST_LIO/config/mid360.yaml")
FAST_ACTIVE = Path("/home/shaun/static/tools/cod_ws/install/fast_lio/share/fast_lio/config/mid360.yaml")
POINT_SOURCE = Path("/home/shaun/static/tools/cod26_ws/src/small_point_lio/config/mid360.yaml")
POINT_ACTIVE = Path("/home/shaun/static/tools/cod26_ws/install/small_point_lio/share/small_point_lio/config/mid360.yaml")
POINT_SIM = Path("/home/shaun/static/tools/cod26_ws/sim/config/mid360_sim.yaml")

REGISTRY = {
    "fastlio": {
        "label": "FAST-LIO",
        "node": "fastlio_mapping",
        "ros_node": "fastlio_mapping",
        "workspace": Path("/home/shaun/static/tools/cod_ws"),
        "package": "fast_lio",
        "executable": "fastlio_mapping",
        "configs": [FAST_ACTIVE, FAST_SOURCE],
        "active": FAST_ACTIVE,
    },
    "pointlio": {
        "label": "Point-LIO",
        "node": "small_point_lio_node",
        "ros_node": "small_point_lio",
        "workspace": Path("/home/shaun/static/tools/cod26_ws"),
        "package": "small_point_lio",
        "executable": "small_point_lio_node",
        "configs": [POINT_ACTIVE, POINT_SOURCE],
        "active": POINT_ACTIVE,
    },
    "pointlio_sim": {
        "label": "Point-LIO (sim)",
        "node": "small_point_lio_node",
        "ros_node": "small_point_lio",
        "workspace": Path("/home/shaun/static/tools/cod26_ws"),
        "package": "small_point_lio",
        "executable": "small_point_lio_node",
        "configs": [POINT_SIM, POINT_SOURCE],
        "active": POINT_SIM,
    },
}

SIM_ONLY = {"pointlio_sim"}
PARAM_MINIMUMS = {
    "point_filter_num": 1,
    "filter_size_surf": 1e-4,
    "filter_size_map": 1e-4,
    "space_downsample_leaf_size": 1e-4,
    "map_resolution": 1e-4,
}


def run_shell(cmd, timeout=10):
    return subprocess.run(
        ["bash", "-lc", cmd],
        capture_output=True,
        text=True,
        timeout=timeout,
    )


def ros_env(workspace, inner):
    return (
        "set +u; "
        "unset AMENT_CURRENT_PREFIX COLCON_CURRENT_PREFIX; "
        "source /opt/ros/humble/setup.bash; "
        f"source {workspace}/install/setup.bash; "
        f"{inner}"
    )


def load_yaml(path):
    with open(path, "r") as f:
        return yaml.safe_load(f)


def save_yaml(path, data):
    with open(path, "w") as f:
        yaml.safe_dump(
            data,
            f,
            sort_keys=False,
            allow_unicode=True,
            default_flow_style=False,
        )


def root_key(data):
    for key, value in data.items():
        if isinstance(value, dict) and isinstance(value.get("ros__parameters"), dict):
            return key
    if isinstance(data.get("ros__parameters"), dict):
        return None
    raise ValueError("找不到 ros__parameters")


def params_of(data):
    key = root_key(data)
    if key is None:
        return data["ros__parameters"]
    return data[key]["ros__parameters"]


def iter_params(params, prefix=""):
    for key, value in params.items():
        path = f"{prefix}.{key}" if prefix else key
        if isinstance(value, dict):
            yield from iter_params(value, path)
        else:
            yield path, value


def find_param(params, dotted):
    node = params
    parts = dotted.split(".")
    for part in parts[:-1]:
        if not isinstance(node, dict) or part not in node:
            raise KeyError(dotted)
        node = node[part]
    if not isinstance(node, dict) or parts[-1] not in node:
        raise KeyError(dotted)
    return node, parts[-1]


def convert_value(old, text):
    if isinstance(old, bool):
        return text.strip().lower() in ("1", "true", "yes", "on")
    if isinstance(old, int) and not isinstance(old, bool):
        return int(text)
    if isinstance(old, float):
        return float(text)
    return text


def validate(key, value):
    if key in PARAM_MINIMUMS and value < PARAM_MINIMUMS[key]:
        raise ValueError(f"{key} 必须 >= {PARAM_MINIMUMS[key]}")


def processes_for(algo):
    node = REGISTRY[algo]["node"]
    out = subprocess.check_output(["ps", "-eo", "pid=,args="], text=True)
    found = []
    for line in out.splitlines():
        line = line.strip()
        if not line:
            continue
        pid, _, args = line.partition(" ")
        if node in args and "lio_tune.py" not in args and "ps -eo" not in args:
            found.append((int(pid), args))
    return found


def kill_processes(algo):
    procs = processes_for(algo)
    for pid, _ in procs:
        try:
            os.kill(pid, signal.SIGTERM)
        except ProcessLookupError:
            pass
    deadline = time.time() + 3
    while time.time() < deadline:
        if not processes_for(algo):
            return
        time.sleep(0.2)
    for pid, _ in processes_for(algo):
        try:
            os.kill(pid, signal.SIGKILL)
        except ProcessLookupError:
            pass
    time.sleep(0.3)


def node_running(algo):
    return bool(processes_for(algo))


def detect_algo():
    running = [a for a in REGISTRY if node_running(a)]
    if len(running) == 1:
        return running[0]
    return None


def topic_exists(workspace, topic):
    result = run_shell(
        ros_env(workspace, f"timeout 3 ros2 topic list 2>/dev/null"),
        timeout=6,
    )
    return topic in result.stdout.split()


def choose_algo(algo=None):
    if algo:
        return algo
    detected = detect_algo()
    if detected:
        return detected
    print("当前没有检测到 LIO 节点。可选：")
    for name, item in REGISTRY.items():
        print(f"  {name:12s} {item['label']}")
    return input("选择算法: ").strip()


def backup_configs(algo):
    REGISTRY[algo]["configs"]
    stamp = datetime.now().strftime("%Y%m%d_%H%M%S_%f")
    backups = {}
    for path in REGISTRY[algo]["configs"]:
        if not path.exists():
            continue
        bak = path.with_name(path.name + f".bak.{stamp}")
        shutil.copy2(path, bak)
        backups[str(path)] = str(bak)
    return backups


def restore_backups(backups):
    for original, backup in backups.items():
        if Path(backup).exists():
            shutil.copy2(backup, original)


def write_param(algo, key, text):
    active = REGISTRY[algo]["active"]
    if not active.exists():
        raise FileNotFoundError(active)

    first = load_yaml(active)
    params = params_of(first)
    holder, leaf = find_param(params, key)
    old = holder[leaf]
    value = convert_value(old, text)
    validate(key, value)

    backups = backup_configs(algo)
    for path in REGISTRY[algo]["configs"]:
        if not path.exists():
            continue
        data = load_yaml(path)
        p = params_of(data)
        h, l = find_param(p, key)
        h[l] = value
        save_yaml(path, data)

    state = {
        "algo": algo,
        "key": key,
        "old": old,
        "new": value,
        "backups": backups,
        "time": datetime.now().isoformat(),
    }
    STATE_FILE.write_text(json.dumps(state, indent=2))
    return old, value, backups


def start_lio(algo, sim, dry_run=False):
    item = REGISTRY[algo]
    active = item["active"]
    sim = True if algo in SIM_ONLY else sim
    inner = (
        "exec ros2 run "
        f"{item['package']} {item['executable']} "
        "--ros-args "
        f"--params-file {active} "
        f"-p use_sim_time:={'true' if sim else 'false'}"
    )
    cmd = ros_env(item["workspace"], inner)
    log_path = LOG_DIR / f"{algo}_{datetime.now().strftime('%Y%m%d_%H%M%S')}.log"
    LOG_DIR.mkdir(parents=True, exist_ok=True)

    if dry_run:
        print("将执行:")
        print(cmd)
        print(f"日志: {log_path}")
        return True, log_path

    with open(log_path, "w") as log:
        subprocess.Popen(
            ["bash", "-lc", cmd],
            stdout=log,
            stderr=subprocess.STDOUT,
            start_new_session=True,
            cwd=str(item["workspace"]),
        )

    deadline = time.time() + 15
    while time.time() < deadline:
        result = run_shell(
            ros_env(item["workspace"], "timeout 3 ros2 node list 2>/dev/null"),
            timeout=5,
        )
        if item["ros_node"] in result.stdout:
            odom = run_shell(
                ros_env(
                    item["workspace"],
                    "timeout 3 ros2 topic echo /Odometry --once >/dev/null 2>&1 && echo YES || echo NO",
                ),
                timeout=6,
            )
            if odom.stdout.strip() == "YES":
                print("节点已启动，/Odometry 正常")
            else:
                print("节点已启动，但暂未看到 /Odometry；请检查 TF 和雷达话题")
            return True, log_path
        time.sleep(0.5)
    return False, log_path


def restart(algo, sim=None, dry_run=False):
    item = REGISTRY[algo]
    if sim is None:
        sim = algo in SIM_ONLY or topic_exists(item["workspace"], "/clock")
    if not dry_run:
        print(f"停止 {item['label']} ...")
        kill_processes(algo)
        time.sleep(0.5)
    print(f"启动 {item['label']} (use_sim_time={str(sim).lower()}) ...")
    ok, log_path = start_lio(algo, sim, dry_run=dry_run)
    print(f"日志: {log_path}")
    print("启动成功" if ok else "启动失败，查看日志")
    return ok


def show_params(algo):
    item = REGISTRY[algo]
    active = item["active"]
    if not active.exists():
        raise FileNotFoundError(active)
    data = load_yaml(active)
    print(f"算法: {item['label']}")
    print(f"配置: {active}")
    print(f"节点: {item['node']}")
    print()
    for key, value in iter_params(params_of(data)):
        print(f"{key:38s} = {value}")


def list_algos():
    for name, item in REGISTRY.items():
        pids = [str(pid) for pid, _ in processes_for(name)]
        running = ",".join(pids) if pids else "未运行"
        print(f"{name:12s} {item['label']:16s} active={item['active']}")
        print(f"{'':12s} node={item['node']} pid={running}")


def interactive():
    algo = choose_algo()
    while True:
        item = REGISTRY[algo]
        print()
        print(f"=== LIO Tuner [{algo}] {item['label']} ===")
        print("1. 查看参数")
        print("2. 修改参数")
        print("3. 重启 LIO")
        print("4. 回滚上次修改")
        print("5. 切换算法")
        print("0. 退出")
        choice = input("选择: ").strip()
        try:
            if choice == "1":
                show_params(algo)
            elif choice == "2":
                key = input("参数名: ").strip()
                value = input("新值: ").strip()
                old, new, _ = write_param(algo, key, value)
                print(f"{key}: {old} -> {new}")
                if input("现在重启 LIO? [y/N]: ").strip().lower() == "y":
                    ok = restart(algo)
                    print("重启成功" if ok else "重启失败，查看日志")
            elif choice == "3":
                ok = restart(algo)
                print("重启成功" if ok else "重启失败，查看日志")
            elif choice == "4":
                rollback()
            elif choice == "5":
                algo = choose_algo()
            elif choice == "0":
                return
        except Exception as exc:
            print(f"错误: {exc}")


def rollback():
    if not STATE_FILE.exists():
        print("没有可回滚的修改")
        return
    state = json.loads(STATE_FILE.read_text())
    algo = state["algo"]
    restore_backups(state.get("backups", {}))
    print(f"已恢复配置: {state.get('key')} = {state.get('old')}")
    print("重启 LIO ...")
    ok = restart(algo)
    print("重启成功" if ok else "重启失败，查看日志")


def main():
    parser = argparse.ArgumentParser(description="LIO 调参并重启")
    sub = parser.add_subparsers(dest="cmd")

    sub.add_parser("list")

    p_show = sub.add_parser("show")
    p_show.add_argument("algo", choices=REGISTRY.keys())

    p_set = sub.add_parser("set")
    p_set.add_argument("algo", choices=REGISTRY.keys())
    p_set.add_argument("key")
    p_set.add_argument("value")
    p_set.add_argument("--restart", action="store_true")
    p_set.add_argument("--dry-run", action="store_true")
    p_set.add_argument("--sim", action="store_true", help="强制 use_sim_time=true")
    p_set.add_argument("--real", action="store_true", help="强制 use_sim_time=false")

    p_restart = sub.add_parser("restart")
    p_restart.add_argument("algo", choices=REGISTRY.keys())
    p_restart.add_argument("--dry-run", action="store_true")
    p_restart.add_argument("--sim", action="store_true", help="强制 use_sim_time=true")
    p_restart.add_argument("--real", action="store_true", help="强制 use_sim_time=false")

    sub.add_parser("rollback")

    args = parser.parse_args()
    if args.cmd is None:
        interactive()
        return

    if args.cmd == "list":
        list_algos()
        return

    algo = getattr(args, "algo", None)
    if args.cmd == "show":
        algo = algo or getattr(args, "algo", None) or choose_algo()
        show_params(algo)
        return

    if args.cmd == "set":
        algo = algo or choose_algo()
        if args.dry_run:
            old = find_param(params_of(load_yaml(REGISTRY[algo]["active"])), args.key)[0][args.key]
            new = convert_value(old, args.value)
            validate(args.key, new)
            print(f"{args.key}: {old} -> {new} (dry-run)")
            return
        old, new, backups = write_param(algo, args.key, args.value)
        print(f"{args.key}: {old} -> {new}")
        print(f"已写入: {', '.join(backups)}")
        if args.restart:
            ok = restart(algo, sim=True if args.sim else False if args.real else None)
            if not ok:
                restore_backups(backups)
                print("启动失败，已回滚配置")
                sys.exit(1)
            print("修改已生效")
        return

    if args.cmd == "restart":
        algo = algo or choose_algo()
        sim = True if args.sim else False if args.real else None
        ok = restart(algo, sim=sim, dry_run=args.dry_run)
        sys.exit(0 if ok else 1)

    if args.cmd == "rollback":
        rollback()


if __name__ == "__main__":
    main()
