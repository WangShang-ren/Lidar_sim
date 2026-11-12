# Meta Workspace 分层说明

## 当前新结构

```text
rm_sim/
├── envs/
│   ├── livox_mid360s/   # 真实雷达驱动 + Livox 消息
│   ├── fastlio/         # FAST-LIO 算法
│   ├── pointlio/        # Point-LIO 算法
│   ├── sim_tools/       # Gazebo、world、maps、pcd2pgm、small_gicp、定位
│   ├── nav_2026/        # Nav2 launch/params/plugins
│   └── rqt_ui/          # rqt_lio_tune 构建环境
├── third_party/
├── scripts/
└── docs/
```

`envs/` 和 `third_party/` 已在 `.gitignore` 中。

## 各环境职责

| 环境 | 主要包 | 依赖 |
|---|---|---|
| `livox_mid360s` | `livox_ros_driver2` | Livox SDK2 |
| `fastlio` | `fast_lio` | `livox_ros_driver2` 消息 |
| `pointlio` | `small_point_lio` | `livox_ros_driver2` 消息 |
| `sim_tools` | `pb_rm_simulation`、`ros2_livox_simulation`、`pcd2pgm`、`ndt_omp_ros2`、`small_gicp_relocalization`、`lidar_localization_ros2`、`patchworkpp` | livox 消息、PCL、Gazebo |
| `nav_2026` | `nav_bringup`、`cod_bringup`、Nav2 插件、`pointcloud_to_laserscan`、`fake_vel_transform`、`cpp_lidar_filter` | Nav2、sim_tools、LIO 输出 |
| `rqt_ui` | `rqt_lio_tune` | rqt_gui_py、python_qt_binding、PyQt5 |

## source 顺序

```bash
source /opt/ros/humble/setup.bash
source envs/livox_mid360s/install/setup.bash
source envs/fastlio/install/setup.bash
source envs/pointlio/install/setup.bash
source envs/sim_tools/install/setup.bash
source envs/nav_2026/install/setup.bash
source envs/rqt_ui/install/setup.bash
```

或者：

```bash
source scripts/setup_split.sh
```

## 已验证

```text
fast_lio          -> envs/fastlio/install/fast_lio
small_point_lio   -> envs/pointlio/install/small_point_lio
pb_rm_simulation  -> envs/sim_tools/install/pb_rm_simulation
ros2_livox_simulation -> envs/sim_tools/install/ros2_livox_simulation
nav_bringup       -> envs/nav_2026/install/nav_bringup
cod_bringup       -> envs/nav_2026/install/cod_bringup
pcd2pgm           -> envs/sim_tools/install/pcd2pgm
rqt_lio_tune      -> import 成功
```

## 切换状态

已切换并验证：

```text
scripts/run_fastlio_2026.sh -> fastlio + sim_tools + nav_2026
scripts/run_pointlio_2026.sh -> pointlio + sim_tools + nav_2026
```

FAST-LIO 和 Point-LIO 两套 2026 仿真均已跑通，目标点 `(4.6, -5.5)` 返回 `SUCCEEDED`。

旧过渡环境 `fastlio_2026` / `pointlio_2026` 已移除。
