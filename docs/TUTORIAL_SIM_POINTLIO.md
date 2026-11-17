# 虚拟仿真：2026 Gazebo + Point-LIO

目标：不接实物雷达，在 Gazebo 中跑 2026 3v3 场地、Point-LIO、Nav2。

## 1. 前置

```bash
source /opt/ros/humble/setup.bash
source /home/shaun/static/Mtools/rm_sim/scripts/setup_split.sh
```

确认：

```bash
ros2 pkg prefix small_point_lio
ros2 pkg prefix cod_bringup
ros2 pkg prefix cpp_lidar_filter
```

## 2. 启动

```bash
/home/shaun/static/Mtools/rm_sim/scripts/run_pointlio_2026.sh
```

脚本会启动：

```text
gzserver + 2026 场地 + 哨兵
Livox 时间戳修正节点
Point-LIO / small_point_lio
cpp_lidar_filter
fake_vel_transform
cod_bringup localization + navigation
RViz
```

日志：

```text
envs/sim_tools/pointlio_sim/logs/sim_YYYYMMDD_HHMMSS/
```

## 3. 检查

```bash
ros2 topic hz /livox/lidar
ros2 topic hz /Odometry
ros2 topic hz /livox/lidar_filtered
```

Nav2：

```bash
ros2 lifecycle get /map_server
ros2 lifecycle get /controller_server
ros2 lifecycle get /bt_navigator
```

## 4. 发点

```bash
/home/shaun/static/Mtools/rm_sim/scripts/go_pointlio_2026.sh 4.6 -5.5 0
```

推荐点位：

```bash
0.0 -2.6
0.0 -5.5
4.6 -6.2
4.6 -5.5
```

## 5. Point-LIO 和 FAST-LIO 入口的区别

| 入口 | 算法 | Nav2 配置 |
|---|---|---|
| `run_fastlio_2026.sh` | FAST-LIO | `nav_bringup` |
| `run_pointlio_2026.sh` | Point-LIO | `cod_bringup` |

不要同时启动两个仿真入口，否则会抢 Gazebo 和 `/livox/lidar`。

## 6. 停止

运行脚本的终端按 `Ctrl+C`。

## 7. 常见问题

### `/Odometry` 没数据

查看：

```bash
tail -80 envs/sim_tools/pointlio_sim/logs/sim_*/point_lio.log
```

检查 Gazebo 时间戳修正节点：

```bash
ros2 topic hz /livox/lidar_fixed
```

### Nav2 启动慢

Point-LIO 和 Nav2 启动比 FAST-LIO 慢一些，等所有 lifecycle 节点变成 `active` 再发点。

### TF 报错

确认：

```bash
ros2 run tf2_ros tf2_echo map base_link_fake
```

应能看到 `map -> odom -> base_link -> base_link_fake`。
