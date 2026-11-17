# LIO 调参：CLI、PyQt5、rqt

目标：不手动改 YAML、不手动找进程，直接查看参数、修改参数、重启 LIO、回滚。

## 1. 三个入口

CLI：

```bash
/home/shaun/static/Mtools/rm_sim/scripts/run_lio_tune.sh
```

PyQt5 小窗口：

```bash
/home/shaun/static/Mtools/rm_sim/scripts/run_lio_tune_gui.sh
```

rqt 插件：

```bash
unset AMENT_CURRENT_PREFIX
unset COLCON_CURRENT_PREFIX

source /opt/ros/humble/setup.zsh
source /home/shaun/static/Mtools/rm_sim/envs/rqt_ui/install/setup.zsh

rqt --force-discover -s rqt_lio_tune.plugin.LioTunerPlugin
```

## 2. CLI 用法

查看配置：

```bash
/home/shaun/static/Mtools/rm_sim/scripts/run_lio_tune.sh list
/home/shaun/static/Mtools/rm_sim/scripts/run_lio_tune.sh show fastlio
/home/shaun/static/Mtools/rm_sim/scripts/run_lio_tune.sh show pointlio
/home/shaun/static/Mtools/rm_sim/scripts/run_lio_tune.sh show pointlio_sim
```

修改参数：

```bash
run_lio_tune.sh set fastlio point_filter_num 2
run_lio_tune.sh set fastlio filter_size_surf 0.3
run_lio_tune.sh set pointlio space_downsample_leaf_size 0.3
```

修改后立即重启：

```bash
run_lio_tune.sh set fastlio point_filter_num 2 --restart
```

只重启：

```bash
run_lio_tune.sh restart fastlio
run_lio_tune.sh restart pointlio
```

强制仿真时间：

```bash
run_lio_tune.sh restart pointlio --sim
```

回滚：

```bash
run_lio_tune.sh rollback
```

先看效果不改文件：

```bash
run_lio_tune.sh set fastlio point_filter_num 2 --dry-run
```

## 3. 四种算法/配置

| 名称 | 用途 |
|---|---|
| `fastlio` | FAST-LIO，真实雷达或仿真算法 |
| `pointlio` | Point-LIO，真实雷达 |
| `pointlio_sim` | Point-LIO 仿真配置 |

## 4. 参数说明

FAST-LIO：

```yaml
point_filter_num: 1   # 每隔 N 个点取 1 个
filter_size_surf: 0.2 # 表面降采样
filter_size_map: 0.4  # 地图降采样
```

Point-LIO：

```yaml
point_filter_num: 1
space_downsample: true
space_downsample_leaf_size: 0.5
```

## 5. 文件位置

FAST-LIO：

```text
envs/fastlio/src/fast_lio/config/mid360.yaml
envs/fastlio/install/fast_lio/share/fast_lio/config/mid360.yaml
```

Point-LIO：

```text
envs/pointlio/src/small_point_lio/config/mid360.yaml
envs/pointlio/install/small_point_lio/share/small_point_lio/config/mid360.yaml
```

Point-LIO 仿真：

```text
envs/sim_tools/pointlio_sim/config/mid360_sim.yaml
```

工具会同时更新源代码和安装配置，并自动备份：

```text
*.bak.YYYYMMDD_HHMMSS
```

状态文件：

```text
tools/lio_tune/state/last_state.json
```

日志：

```text
tools/lio_tune/logs/
```

旧的外部目录 `/home/shaun/static/Mtools/lio_tune` 只作为历史兼容，不再作为主路径。

## 6. 注意

```text
LIO 参数多数是启动时读取的
改完必须重启对应 LIO 节点
```

工具只重启：

```text
fastlio_mapping
small_point_lio
```

不会重启：

```text
雷达驱动
Gazebo
Nav2
```

重启时 `/Odometry` 和 TF 会短暂中断，Nav2 当前目标可能中断。

## 7. GUI / rqt 的功能

- 启动雷达 + RViz
- 停止雷达 + RViz
- 重启 LIO
- 停止 LIO
- 修改参数
- 应用
- 应用 + 重启
- 回滚
- 日志显示

## 8. 双击启动 LIO Tuner

桌面上已经放好：

```text
~/Desktop/LIO-Tuner.desktop
```

应用菜单里也安装了：

```text
~/.local/share/applications/LIO-Tuner.desktop
```

直接双击 `LIO Tuner` 即可启动。

如果桌面提示“不受信任”，右键选择“允许启动”：

```text
Allow Launching
```

或者命令行启动：

```bash
gtk-launch LIO-Tuner
```

对应脚本：

```text
scripts/run_lio_tune_gui.sh
```

## 9. 在 LIO Tuner 里启动仿真

窗口按钮：

```text
启动雷达+RViz
停止雷达+RViz
启动 FAST-LIO 仿真
启动 Point-LIO 仿真
停止全部
```

使用方式：

```text
只看真实雷达 -> 启动雷达+RViz
跑 FAST-LIO 2026 仿真 -> 启动 FAST-LIO 仿真
跑 Point-LIO 2026 仿真 -> 启动 Point-LIO 仿真
```

注意：

```text
不要同时启动真实雷达和仿真
不要同时启动 FAST-LIO 和 Point-LIO 仿真
换模式前先点“停止全部”
```

仿真启动后，RViz 会自动打开，日志显示在窗口底部。

## 10. 调参和重启

1. 在“算法”下拉框选择 `fastlio` / `pointlio` / `pointlio_sim`
2. 点“查看参数”
3. 选中一行参数
4. 输入新值
5. 点“应用”或“应用+重启”
6. 需要撤销时点“回滚”

工具只重启 LIO，不会重启 Gazebo、雷达驱动或 Nav2。
