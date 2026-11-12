import os
from ament_index_python.packages import get_package_share_directory

from launch import LaunchDescription
from launch.actions import ExecuteProcess, TimerAction
from launch.substitutions import Command
from launch_ros.actions import Node
from launch_ros.parameter_descriptions import ParameterValue

WORLD = os.path.join(os.path.dirname(__file__), '..', 'worlds', 'rmul2026.world')
ROBOT_XACRO = os.path.join(get_package_share_directory('pb_rm_simulation'), 'urdf', 'simulation_waking_robot.xacro')


def generate_launch_description():
    robot_description = ParameterValue(
        Command(['xacro ', ROBOT_XACRO]),
        value_type=str,
    )

    gazebo = ExecuteProcess(
        cmd=[
            'gzserver', '--verbose',
            '-s', 'libgazebo_ros_init.so',
            '-s', 'libgazebo_ros_factory.so',
            WORLD,
        ],
        output='screen',
    )

    robot_state_publisher = Node(
        package='robot_state_publisher',
        executable='robot_state_publisher',
        name='robot_state_publisher',
        output='screen',
        parameters=[{
            'use_sim_time': True,
            'robot_description': robot_description,
        }],
    )

    joint_state_publisher = Node(
        package='joint_state_publisher',
        executable='joint_state_publisher',
        name='joint_state_publisher',
        output='screen',
        parameters=[{
            'use_sim_time': True,
            'robot_description': robot_description,
        }],
    )

    spawn_entity = Node(
        package='gazebo_ros',
        executable='spawn_entity.py',
        output='screen',
        arguments=[
            '-entity', 'sentry',
            '-topic', 'robot_description',
            '-x', '-4.8',
            '-y', '0.0',
            '-z', '0.35',
            '-Y', '0.0',
        ],
    )

    return LaunchDescription([
        gazebo,
        robot_state_publisher,
        joint_state_publisher,
        TimerAction(period=3.0, actions=[spawn_entity]),
    ])
