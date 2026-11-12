#!/usr/bin/env python3
"""Fix the timebase of Livox CustomMsg messages."""

import rclpy
from rclpy.node import Node
from livox_ros_driver2.msg import CustomMsg


class LivoxTimebaseFix(Node):
    def __init__(self):
        super().__init__("livox_timebase_fix")
        self.publisher = self.create_publisher(CustomMsg, "/livox/lidar_fixed", 10)
        self.subscription = self.create_subscription(
            CustomMsg, "/livox/lidar", self.callback, 10
        )

    def callback(self, msg):
        msg.timebase = msg.header.stamp.sec * 1_000_000_000 + msg.header.stamp.nanosec
        self.publisher.publish(msg)


def main():
    rclpy.init()
    node = LivoxTimebaseFix()
    try:
        rclpy.spin(node)
    except KeyboardInterrupt:
        pass
    finally:
        node.destroy_node()
        rclpy.shutdown()


if __name__ == "__main__":
    main()
