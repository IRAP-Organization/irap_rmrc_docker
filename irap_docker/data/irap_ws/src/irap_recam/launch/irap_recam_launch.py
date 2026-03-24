import socket
import re
from launch import LaunchDescription
from launch.actions import DeclareLaunchArgument
from launch.substitutions import LaunchConfiguration
from launch_ros.actions import Node


def get_namespace() -> str:
    """
    Derive ROS namespace from hostname.
    Examples:
      rmrc-07  ->  rmrc_7
      rmrc-03  ->  rmrc_3
      rmrc-12  ->  rmrc_12
    """
    hostname = socket.gethostname()          # e.g. 'arduino@rmrc-07' or 'rmrc-07'
    hostname = hostname.split('@')[-1]       # strip user@ prefix if present
    match = re.search(r'(\D+)-?0*(\d+)$', hostname)
    if match:
        prefix = match.group(1).replace('-', '_').strip('_')  # rmrc- -> rmrc
        number = match.group(2)                                # 7 (leading zeros stripped)
        return f'{prefix}_{number}'                            # rmrc_7
    # fallback: just sanitize the raw hostname
    return re.sub(r'[^a-zA-Z0-9_]', '_', hostname)


NAMESPACE = get_namespace()


def generate_launch_description():
    device_arg = DeclareLaunchArgument(
        'device',
        default_value='/dev/ttyMSM0',
        description='Serial device path'
    )
    baudrate_arg = DeclareLaunchArgument(
        'baudrate',
        default_value='4000000',
        description='Serial baudrate'
    )
    recam_node = Node(
        package='irap_recam',
        executable='irap_recam',
        name='irap_recam',
        namespace=NAMESPACE,
        output='screen',
        parameters=[{
            'device': LaunchConfiguration('device'),
            'baudrate': LaunchConfiguration('baudrate'),
            'cam_resolution': 5,
            'cam_quality': 25,
            'cam_brightness': 0,
            'cam_contrast': 0,
            'cam_saturation': 0,
            'cam_exposure': 0,
        }],
        remappings=[
            ('recam/image_raw', f'/{NAMESPACE}/recam/image_raw'),
        ]
    )
    return LaunchDescription([
        device_arg,
        baudrate_arg,
        recam_node
    ])
