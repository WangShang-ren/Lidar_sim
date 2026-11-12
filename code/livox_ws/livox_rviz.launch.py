import os

from ament_index_python.packages import get_package_share_directory
from launch import LaunchDescription
from launch_ros.actions import Node


def generate_launch_description():
    config_dir = os.path.join(
        get_package_share_directory('livox_ros_driver2'), 'config')
    user_config = os.path.join(config_dir, 'MID360s_config.json')
    rviz_config = os.path.join(os.path.dirname(__file__), 'livox_pointcloud.rviz')

    static_tf = Node(
        package='tf2_ros',
        executable='static_transform_publisher',
        name='world_to_livox_frame',
        arguments=[
            '--x', '0', '--y', '0', '--z', '0',
            '--roll', '0', '--pitch', '0', '--yaw', '0',
            '--frame-id', 'world',
            '--child-frame-id', 'livox_frame',
        ],
        output='screen',
    )

    driver = Node(
        package='livox_ros_driver2',
        executable='livox_ros_driver2_node',
        name='livox_lidar_publisher',
        output='screen',
        parameters=[{
            'xfer_format': 0,
            'multi_topic': 0,
            'data_src': 0,
            'publish_freq': 10.0,
            'output_data_type': 0,
            'frame_id': 'livox_frame',
            'lvx_file_path': '/tmp/livox_test.lvx',
            'user_config_path': user_config,
            'cmdline_input_bd_code': 'livox0000000001',
        }],
    )

    rviz = Node(
        package='rviz2',
        executable='rviz2',
        output='screen',
        arguments=['-d', rviz_config],
    )

    return LaunchDescription([static_tf, driver, rviz])
