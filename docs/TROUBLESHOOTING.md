# 常见问题排查

## 1. `source /opt/ros/humble/setup.bash` 报错

错误：

```text
没有那个文件或目录: /home/shaun/setup.sh
```

原因：终端残留了 `AMENT_CURRENT_PREFIX`。

处理：

```bash
unset AMENT_CURRENT_PREFIX
unset COLCON_CURRENT_PREFIX
source /opt/ros/humble/setup.sh
```

或者直接：

```bash
source /home/shaun/static/Mtools/rm_sim/scripts/setup_split.sh
```

---

## 2. 没有 `enxfce...` 网卡

现象：

```text
ip -br addr 只有 wlp1s0
```

原因：

- USB 网卡没插好
- USB Hub 掉电
- USB 网卡重新枚举后换了名字

处理：

```bash
lsusb
ip -br addr
```

重新插拔 USB 网卡/电源，直到出现 `enx...`。

---

## 3. USB 网卡是 `196.168.1.50`

现象：

```text
enxfce...  196.168.1.50/24
```

这是错误地址，不是 `192`。

处理：

```bash
sudo ip addr add 192.168.1.50/24 dev <enx网卡>
sudo ip link set <enx网卡> up
```

然后：

```bash
ping -c 3 192.168.1.137
```

---

## 4. `ping 192.168.1.137` 不通

检查：

```text
雷达是否供电
网线是否接在 USB 网卡上
主机是否是 192.168.1.50
雷达 IP 是否还是 .137
```

查看：

```bash
ip -br addr
ip neigh
```

---

## 5. 驱动报 `bind failed`

完整错误：

```text
bind failed
Failed to init livox lidar sdk.
Init lds lidar fail!
```

常见原因：

1. 主机没有 `192.168.1.50`
2. 旧驱动还占着端口
3. 雷达没上电
4. 另一个 Livox 驱动正在运行

检查：

```bash
ip -br addr
ss -lunp | grep 56000
ps -ef | grep livox
```

先停旧驱动，再启动新的。

---

## 6. `/livox/lidar` 没有数据

```bash
ros2 topic list | grep livox
ros2 topic type /livox/lidar
ros2 topic hz /livox/lidar
```

可能原因：

- 驱动没起来
- 雷达 IP 不对
- 网卡不对
- 雷达没供电

如果是 MID-360S，确认配置是：

```text
MID360s_config.json
```

不是 `MID360_config.json`。

---

## 7. `/livox/lidar` 同时出现两种类型

现象：

```text
Cannot echo topic '/livox/lidar', as it contains more than one type:
[livox_ros_driver2/msg/CustomMsg, sensor_msgs/msg/PointCloud2]
```

原因：同时有两个发布者：

- 旧驱动
- 新驱动
- 或 FAST-LIO 旧节点

检查：

```bash
ros2 topic info /livox/lidar -v
ps -ef | grep -E 'livox|fastlio|small_point'
```

只保留一个驱动和一模式：

```text
rviz_MID360s_launch.py  -> PointCloud2
msg_MID360s_launch.py   -> CustomMsg
```

---

## 8. RViz 报 `Frame [livox_frame] does not exist`

原因：没有 `livox_frame` 的 TF。

独立雷达：

```text
world -> livox_frame
```

检查：

```bash
ros2 run tf2_ros tf2_echo world livox_frame
```

RViz：

```text
Fixed Frame: world
```

如果使用机器人：

```text
base_link -> livox_frame
```

---

## 9. Gazebo GUI 崩溃

现象：

```text
OgreAxisAlignedBox ... assertion
```

本机 Gazebo Classic `gzclient` 有 Ogre 崩溃。  
仿真入口使用 `gzserver` 无界面，可视化用 RViz。

---

## 10. 没有 `/Odometry`

检查：

```bash
ros2 topic list | grep -E 'Odometry|cloud_registered'
ros2 node list | grep -E 'fastlio|small_point'
```

如果 LIO 节点在，但没有 odom：

- TF `base_link -> livox_frame` 缺失
- 点云时间戳不对
- IMU 没有数据
- LIO 配置不匹配

---

## 11. PCD 没有生成

FAST-LIO：

```yaml
pcd_save:
  pcd_save_en: true
map_file_path: "/home/shaun/static/Mtools/rm_sim/pcd/fastlio_scan.pcd"
```

Point-LIO：

```yaml
save_pcd: true
```

并调用：

```bash
ros2 service call /map_save std_srvs/srv/Trigger
```

---

## 12. Nav2 目标 `ABORTED`

检查：

```bash
ros2 run tf2_ros tf2_echo map base_link_fake
ros2 topic hz /scan
ros2 topic hz /livox/lidar_filtered
```

2026 地图/场地存在局部偏差，右侧和中央部分点位可能卡住；先用左侧和底部点位。

---

## 13. Git push 报 TLS 错误

错误：

```text
GnuTLS recv error (-110)
```

原因：GitHub 直连被中断。

Clash 端口是 `7897` 时：

```bash
git config http.proxy http://127.0.0.1:7897
git config https.proxy http://127.0.0.1:7897
git push origin master
```

如果 remote 是别人的仓库，先改成自己的：

```bash
git remote set-url origin <你的仓库地址>
```
