# 虚拟仿真：2026 Gazebo + FAST-LIO

目标：不接实物雷达，在 Gazebo 中跑 2026 3v3 场地、FAST-LIO、Nav2，并发送目标点。

## 1\. 前置

已经完成编译：

```bash
source /opt/ros/humble/setup.bash
source /home/shaun/static/Mtools/rm_sim/scripts/setup_split.sh
```

确认：

```bash
ros2 pkg prefix fast_lio
ros2 pkg prefix nav_bringup
ros2 pkg prefix pb_rm_simulation
```

## 2\. 启动仿真

```bash
/home/shaun/static/Mtools/rm_sim/scripts/run_fastlio_2026.sh
```

脚本会启动：

```text
gzserver（无 Gazebo GUI）
Gazebo Livox 插件 + 2026 场地 + 哨兵
FAST-LIO
Nav2
RViz
```

日志目录：

```text
envs/sim_tools/sim2026/logs/sim_YYYYMMDD_HHMMSS/
```

启动完成后会显示：

```text
Nav2 状态:
  /map_server              active [3]
  /controller_server       active [3]
  ...
```

## 3\. 看效果

RViz 中重点 Topic：

```text
/livox/lidar/pointcloud
/scan
/plan
/local_costmap/costmap
/global_costmap/costmap
```

如果 RViz 没有自动打开，可以手动：

```bash
source /home/shaun/static/Mtools/rm_sim/scripts/setup_split.sh
rviz2 -d /home/shaun/static/Mtools/rm_sim/envs/nav_2026/install/nav_bringup/share/nav_bringup/rviz/cod_nav.rviz
```

## 4\. 发送目标点

```bash
/home/shaun/static/Mtools/rm_sim/scripts/go_fastlio_2026.sh 4.6 -5.5 0

```

推荐先试：

```bash
/home/shaun/static/Mtools/rm_sim/scripts/go_fastlio_2026.sh 0.0 -2.6 0
/home/shaun/static/Mtools/rm_sim/scripts/go_fastlio_2026.sh 0.0 -5.5 0
/home/shaun/static/Mtools/rm_sim/scripts/go_fastlio_2026.sh 4.6 -6.2 0
/home/shaun/static/Mtools/rm_sim/scripts/go_fastlio_2026.sh 4.6 -5.5 0
```

成功会显示：

```text
Goal finished with status: SUCCEEDED
```

## 5\. 停止

在运行脚本的终端按 `Ctrl+C`，会清理 Gazebo、FAST-LIO、Nav2 和 RViz。

## 6\. 无 RViz 启动

只测试后台：

```bash
NO_RVIZ=1 /home/shaun/static/Mtools/rm_sim/scripts/run_fastlio_2026.sh
```

## 7\. 常见问题

### Gazebo GUI 没出来

这是正常的。本机 Gazebo Classic `gzclient` 有 Ogre 崩溃，仿真只用 `gzserver`，效果看 RViz。

### 一直卡在 `[1/5]`

检查：

```bash
ros2 topic list | grep -E 'clock|livox'
```

### Nav2 不 active

查看日志：

```bash
ls -dt /home/shaun/static/Mtools/rm_sim/envs/sim_tools/sim2026/logs/sim_* | head -1
```

### RViz 没有路径

添加 `Path` 显示，Topic 选：

```text
/plan
```
