# TF 和 RViz PointCloud2 说明

## 老师指出的问题

老师主要指出两点：

1. 没有说明 `livox_frame` 与其他坐标系的 TF 关系
2. RViz 里点云显示太稀/太密，需要调 PointCloud2 显示参数

这两点对应的修复如下。

## 1. TF 关系

独立启动 MID-360S 时，驱动只发布点云：

```text
/livox/lidar
  header.frame_id = livox_frame
```

但驱动本身不发布 `livox_frame` 的 TF，所以 RViz 会报：

```text
Fixed Frame: No tf data. Frame [livox_frame] does not exist
```

### 修复方式

在 `code/livox_ws/livox_rviz.launch.py` 中增加静态 TF：

```text
world -> livox_frame
```

参数：

```text
x=0, y=0, z=0
roll=0, pitch=0, yaw=0
```

这是老师建议的“不上实车时写到世界坐标系”。  
对应 launch 片段：

```python
static_tf = Node(
    package='tf2_ros',
    executable='static_transform_publisher',
    arguments=[
        '--x', '0', '--y', '0', '--z', '0',
        '--roll', '0', '--pitch', '0', '--yaw', '0',
        '--frame-id', 'world',
        '--child-frame-id', 'livox_frame',
    ],
)
```

### 仿真 TF 链

2026 COD_NAV + FAST-LIO：

```text
map -> odom -> chassis -> chassis_fake
chassis -> livox_frame
```

2026 COD_RM2026 + Point-LIO：

```text
map -> odom -> base_link -> base_link_fake
base_link -> livox_frame
```

实车：

```text
map -> odom -> base_link
base_link -> livox_frame   # 使用真实安装外参
```

### 查看 TF 树

```bash
ros2 run rqt_tf_tree rqt_tf_tree
```

或者：

```bash
ros2 run tf2_tools view_frames
```

检查：

```bash
ros2 run tf2_ros tf2_echo world livox_frame
```

## 2. RViz 中订阅 PointCloud2

`code/livox_ws/livox_pointcloud.rviz` 已经显式配置：

```text
Fixed Frame: world
Topic:       /livox/lidar
Type:        sensor_msgs/msg/PointCloud2
Style:       Flat Squares
Size (m):    0.02
Decay Time:  0.5
Alpha:       1
Color:       Intensity
```

### 为什么之前看着稀疏

常见原因：

1. RViz 没有订阅 `PointCloud2`，或者订阅了错误话题
2. `Decay Time` 太小，只显示当前一帧
3. `Size (m)` 太小，点看起来很少
4. Fixed Frame 没有 TF，点云无法正常变换

### 推荐调节

```text
Decay Time:
  0      -> 只显示当前帧，最稀
  0.3~0.5-> 推荐
  1~2    -> 更密，但移动时可能拖影

Size (m):
  0.01   -> 细
  0.02   -> 推荐
  0.03~0.05 -> 更明显，但不是实际点数量
```

注意：

```text
Decay Time 是显示累积，不是传感器真实密度
Size 是点的显示大小，不是降采样
```

真正的点云数量由以下参数决定：

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

## 3. 启动方式

新脚本：

```bash
/home/shaun/static/tools/livox_ws/run_mid360s_rviz.sh
```

会自动启动：

```text
world -> livox_frame 静态 TF
livox_ros_driver2（PointCloud2 模式）
rviz2（livox_pointcloud.rviz）
```

PyQt5 GUI 和 rqt 插件的“启动雷达+RViz”按钮也已经改成调用这个脚本。
