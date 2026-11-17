# 串口协议与 COD 代码位置

本文只讲 2026 COD 导航里“上位机发送速度给下位机”的串口协议。

## 1. 代码位置

源码目录：

```text
envs/nav_2026/src/ros2_simple_serial/
```

关键文件：

```text
envs/nav_2026/src/ros2_simple_serial/src/cod_serial.cpp
envs/nav_2026/src/ros2_simple_serial/src/uart_transporter.hpp
envs/nav_2026/src/ros2_simple_serial/src/uart_transporter.cpp
envs/nav_2026/src/ros2_simple_serial/CMakeLists.txt
envs/nav_2026/src/ros2_simple_serial/package.xml
```

ROS 包名：

```text
cod_serial_ul26
```

可执行文件：

```text
install/cod_serial_ul26/lib/cod_serial_ul26/cod_serial
```

launch 里的位置：

```text
envs/nav_2026/src/cod_bringup/launch/singlenav_launch.py:96
envs/nav_2026/src/cod_bringup/launch/multiplenav_launch.py:124
```

注意 `nav_bringup/launch/bringup.launch.py:95` 写的是旧包名：

```python
package='cod_serial'
executable='cod_serial'
```

而当前源码包名是 `cod_serial_ul26`。如果走这个 launch，会报找不到 `cod_serial`。

## 2. 数据流

```text
Nav2 / controller
        |
        v
/aft_cmd_vel  geometry_msgs/msg/Twist
        |
        v
cod_serial_ul26/cod_serial
        |
        v
/dev/ttyACM0  115200 8N1
        |
        v
下位机
```

`cod_serial` 订阅：

```text
/aft_cmd_vel
```

不是直接订阅 `/cmd_vel`。`aft_cmd_vel` 通常由 `fake_vel_transform` 产生。

仿真里还会把：

```text
/aft_cmd_vel -> /cmd_vel_sim
```

送进 Gazebo 小车。

## 3. 串口参数

代码里写死：

```text
设备: /dev/ttyACM0
波特率: 115200
数据位: 8
停止位: 1
校验: None
流控: None
```

即：

```text
115200 8N1
```

串口在每条 Twist 回调里打开、写入、关闭：

```cpp
UartTransporter uart("/dev/ttyACM0", 115200);
uart.open();
uart.writeBuffer(packet, sizeof(packet));
uart.close();
```

这种方式实现简单，但高频发送时效率低，也可能丢帧。

## 4. 发送协议

每次发送固定 15 字节：

```text
偏移  长度  类型       内容
0     1     uint8      帧头 0xA5
1     4     float      线速度 vx
5     4     float      线速度 vy
9     4     float      第三轴速度 vz
13    2     uint16     校验和
```

总长度：

```text
1 + 4 + 4 + 4 + 2 = 15 字节
```

数值按本机小端序直接 `memcpy`，当前 x86/ARM 都是小端。

### 4.1 字段来源

```cpp
float vx = msg->linear.x;
float vy = msg->linear.y;
float vz = msg->linear.z;
```

对应：

```text
vx <- linear.x
vy <- linear.y
vz <- linear.z
```

### 4.2 重要问题：第三轴不是 angular.z

当前代码发送的是：

```text
msg->linear.z
```

但差速/全向底盘通常需要的是：

```text
msg->angular.z
```

也就是偏航角速度。

如果下位机把第 9-12 字节当成 `wz` 使用，那么现在上位机发的是 `linear.z`，通常一直是 0，小车就不会转。

需要和电控确认下位机协议：

```text
第 9-12 字节到底是 linear.z 还是 angular.z
```

如果确认是角速度，应改成：

```cpp
float vz = msg->angular.z;
```

## 5. 校验和

校验和是 16 位无符号整数：

```cpp
uint16_t checksum = header;
for (int i = 1; i < 13; ++i) {
  checksum += packet[i];
}
```

也就是：

```text
checksum = 0xA5 + 第 1 到第 12 字节之和
```

按 uint16 自然溢出，最后写入：

```text
packet[13] = checksum 低字节
packet[14] = checksum 高字节
```

注意：

```text
校验和是逐字节求和，不是 CRC
没有帧尾
没有长度字段
接收端依靠 0xA5 帧头重新同步
```

## 6. 示例

发送：

```text
vx = 1.0
vy = 0.0
vz = 0.0
```

`float 1.0` 小端：

```text
00 00 80 3F
```

完整数据：

```text
A5 00 00 80 3F 00 00 00 00 00 00 00 00 64 01
```

校验：

```text
0xA5 + 0x00 + 0x00 + 0x80 + 0x3F = 0x0164
低字节 0x64，高字节 0x01
```

## 7. 接收方向

`ros2_simple_serial` 目前只发送，不接收。

代码里没有：

```text
串口读取线程
/serial/receive 发布者
比赛信息解析
```

但 `envs/nav_2026/src/nav_bringup/scripts/bt.sh:17` 会读：

```text
/serial/receive
```

并取：

```text
game_type
```

所以 `/serial/receive` 不是这个包发的，应该来自另一套下位机/裁判系统串口接收节点。

如果只启动 `cod_serial_ul26`，`bt.sh` 会一直拿不到 `game_type`。

## 8. 已知问题

```text
1. 第 9-12 字节当前是 linear.z，可能应为 angular.z
2. 每帧都 open/close 串口，高频下效率低
3. 没有接收线程，不能读下位机/裁判系统数据
4. 没有 CRC、帧尾、长度字段，只有累加和
5. 串口设备和波特率写死，不能通过参数配置
6. nav_bringup/bringup.launch.py 仍使用旧包名 cod_serial
```

## 9. 编译与测试

编译：

```bash
source /opt/ros/humble/setup.bash
cd /home/shaun/static/Mtools/rm_sim/envs/nav_2026
colcon build --packages-select cod_serial_ul26 --symlink-install
source install/setup.zsh
```

确认可执行文件：

```bash
ros2 pkg executables cod_serial_ul26
```

应看到：

```text
cod_serial_ul26 cod_serial
```

给串口权限：

```bash
sudo usermod -aG dialout "$USER"
```

重新登录后生效。

测试发送：

```bash
ros2 run cod_serial_ul26 cod_serial

# 另一个终端
ros2 topic pub /aft_cmd_vel geometry_msgs/msg/Twist \
  "{linear: {x: 1.0, y: 0.0, z: 0.0}, angular: {x: 0.0, y: 0.0, z: 0.5}}"
```

用逻辑分析仪或下位机确认收到的 15 字节是否符合协议。
