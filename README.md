# RMUL 2026 3v3 Simulation + LIO Tuning Toolkit

整理自 RMUL 2026 3v3 导航仿真调试过程，包含：

- COD 2026 / Gazebo Classic 仿真入口
- FAST-LIO / Point-LIO 两套 LIO 启动方式
- MID-360S 真实雷达启动脚本
- LIO 参数调优 CLI、PyQt5 小窗口、rqt 插件
- 2026 地图、场地 STL、效果截图、压缩效果视频
- 2026 地图 PCD

> 本仓库是“仿真入口 + 工具 + 素材”的整理包，不包含完整的 COD_NAV、COD_RM2026_Navigation、Livox SDK 源码。完整运行需要按下方说明准备上游依赖。

## 效果

| 真实雷达 RViz 点云 | LIO Tuner GUI |
| ------------ | ------------- |
| ![](media/images/lidar_pointcloud_rviz.png) | ![](media/images/lio_tuner_gui.png) |

| rqt 插件 | 真实雷达 + GUI 视角 |
| ------ | ------------- |
| ![](media/images/rqt_lio_tune.png) | ![](media/images/rviz_pointcloud.png) |

| 2026 仿真 RViz |
| ------------ |
| ![](media/images/sim2026_rviz.png) |

效果视频：

- [真实雷达 RViz 点云](media/videos/lidar_pointcloud_rviz.mp4)
- [真实雷达 + GUI 点云](media/videos/lidar_pointcloud_gui.mp4)
- [2026 仿真 RViz 片段](media/videos/sim2026_navigation.mp4)

## 已验证结果

- 2026 地图 Nav2 目标 `(4.6, -5.5)` 返回 `SUCCEEDED`
- 真实 MID-360S `/livox/lidar` 约 `10 Hz`
- 推荐可跑通点位：左侧和底部走廊
  - `(0.0, -2.6)`
  - `(0.0, -5.5)`
  - `(4.6, -6.2)`
  - `(4.6, -5.5)`

## 目录结构

```text
.
├── code/
│   ├── sim2026/                 # COD_NAV + FAST-LIO + 2026 场地的仿真入口
│   ├── cod26_sim/               # COD_RM2026 + Point-LIO 的仿真入口
│   └── livox_ws/                # MID-360S 驱动启动脚本和配置示例
├── tools/lio_tune/              # 自研 LIO 调参工具
│   ├── lio_tune.py              # CLI / 交互菜单
│   ├── lio_tuner_gui.py         # PyQt5 小窗口
│   └── rqt_plugin/              # rqt 插件源码
├── assets/
│   ├── maps/                    # rmul2026.pgm / yaml
│   └── worlds/                  # 2026 场地 STL / world
├── media/
│   ├── images/
│   └── videos/
├── pcd/RM2026.pcd               # 2026 地图点云（来源见 pcd/README.md）
└── docs/
    ├── CHANGES.md
    └── THIRD_PARTY.md
```

## 依赖环境

- Ubuntu 22.04
- ROS 2 Humble
- Gazebo Classic 11
- Nav2 Humble
- Livox SDK2
- livox_ros_driver2（MID-360S 需要较新版本，本项目实测 1.2.8）
- 上游仓库：
  - [qza36/COD_NAV](https://github.com/qza36/COD_NAV)
  - [codnavgation/cod\_-rm2026\_-navigation](https://gitee.com/codnavgation/cod_-rm2026_-navigation)
  - [Livox-SDK/livox_ros_driver2](https://github.com/Livox-SDK/livox_ros_driver2)
  - [Livox-SDK/Livox-SDK2](https://github.com/Livox-SDK/Livox-SDK2)

## 当前机器上的直接运行命令

> 下面路径是本机整理后的真实路径，换机器时请替换为你的工作区路径。

### 1\. 真实 MID-360S 雷达 + RViz

```bash
/home/shaun/static/tools/livox_ws/run_mid360s_rviz.sh
```

要求：

```text
USB 网卡: 192.168.1.50/24
雷达 IP: 192.168.1.137
```

检查：

```bash
ip -br addr
ping -c 3 192.168.1.137
```

### 2\. 2026 COD_NAV + FAST-LIO 仿真

```bash
/home/shaun/static/tools/cod_ws/sim2026/run_sim_2026.sh
```

发点：

```bash
/home/shaun/static/tools/cod_ws/go_to.sh 4.6 -5.5 0
```

### 3\. 2026 COD_RM2026 + Point-LIO 仿真

```bash
/home/shaun/static/tools/cod26_ws/sim/run_cod26_sim.sh
```

发点：

```bash
/home/shaun/static/tools/cod26_ws/sim/go_cod26.sh 4.6 -5.5 0
```

## LIO 调参工具

CLI：

```bash
python3 /home/shaun/static/Mtools/lio_tune/lio_tune.py
```

常用：

```bash
python3 /home/shaun/static/Mtools/lio_tune/lio_tune.py list
python3 /home/shaun/static/Mtools/lio_tune/lio_tune.py show fastlio
python3 /home/shaun/static/Mtools/lio_tune/lio_tune.py set fastlio point_filter_num 2 --restart
python3 /home/shaun/static/Mtools/lio_tune/lio_tune.py restart pointlio
python3 /home/shaun/static/Mtools/lio_tune/lio_tune.py rollback
```

PyQt5 小窗口：

```bash
python3 /home/shaun/static/Mtools/lio_tune/lio_tuner_gui.py
```

rqt 插件：

```bash
unset AMENT_CURRENT_PREFIX
unset COLCON_CURRENT_PREFIX

source /opt/ros/humble/setup.zsh
source /home/shaun/static/Mtools/lio_tune/rqt_ws/install/setup.zsh

rqt --force-discover -s rqt_lio_tune.plugin.LioTunerPlugin
```

### 调参可改参数

FAST-LIO：

```yaml
point_filter_num: 1
filter_size_surf: 0.2
filter_size_map: 0.4
```

Point-LIO：

```yaml
point_filter_num: 1
space_downsample: true
space_downsample_leaf_size: 0.5
```

工具会自动备份配置，重启对应 LIO 节点；不会重启雷达驱动、Gazebo 或 Nav2。

## 迁移到自己的目录

本包中的脚本来自本机整理路径。复制到自己的 workspace 后，建议先搜索：

```bash
grep -R "/home/shaun/static" .
```

然后把脚本里的绝对路径改成自己的路径，或使用环境变量。

## 已知问题

1. **MID-360S** 
   - 必须使用 `MID360s_config.json` 和较新 `livox_ros_driver2`。
   - 实测 `livox_ros_driver2 1.2.8` 可用。
   - Livox Viewer 2.3.0 不支持 MID-360S。
2. **Gazebo GUI 崩溃**
   - 本机 Gazebo Classic `gzclient` 有 Ogre 断言崩溃。
   - 仿真入口使用 `gzserver` 无界面 + RViz 显示。
3. **2026 地图和社区场地 STL 存在局部偏差**
   - 左侧和底部走廊点位已跑通。
   - 右侧/中央部分点位可能卡住，需要重新对齐地图和世界模型。
4. **RViz 黄色 TF 警告**
   - 独立启动雷达时没有 `livox_frame` TF。
   - 增加静态 TF：

     ```bash
     ros2 run tf2_ros static_transform_publisher \
       --x 0 --y 0 --z 0 --roll 0 --pitch 0 --yaw 0 \
       --frame-id map --child-frame-id livox_frame
```

## 关于 PCD

`pcd/RM2026.pcd` 是 2026 地图点云参考文件，来源说明见 [pcd/README.md](pcd/README.md)。  
本仓库没有包含完整建图过程产生的新 PCD；如需保存自己的 PCD，请参考文档中的建图命令或替换该文件。

## 说明

- 本仓库整理的是仿真入口、配置、自研工具和效果素材。
- 完整运行仍需要上游 COD_NAV / COD_RM2026_Navigation / Livox 驱动。
- 第三方代码、地图和场地模型版权归各自作者所有，详见 [docs/THIRD_PARTY.md](docs/THIRD_PARTY.md)。
