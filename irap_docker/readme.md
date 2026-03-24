// irap-recam esp32-cam stream bridge ros2 humble

// don't change a folder name the folder name must be irap_docker inside docker-compose.yml that fixed the name of volume bridge as irap_docker 
// Read this before installation firmware of xiao-esp32-cam-s3
1.Now u must in irap_docker folder that u pull me on github 
2.Go to espcam_firmware folder 
3.Install esptool on pip if you don't have u must use `pip install esptool` and `sudo apt install esptool` or in windows 
4.plug-in esp32-cam in to your pc and go to espcam-firmware folder and using `python3 -m esptool --chip esp32s3 --port /dev/ttyACM0 --baud 460800 write_flash 0x0000 bootloader.bin  0x10000 firmware.bin` command and replace --port with your port if u in ubuntu or linux u can check by ls /dev/tty* if u in windows u check on device manager and com port run this 
5.after finished u must got this output

nathaphat@irap:~/complete_rmrc/irap_docker/espcam_firmware$ python3 -m esptool --chip esp32s3 --port /dev/ttyACM1 --baud 460800 write_flash 0x0000 bootloader.bin  0x10000 firmware.bin
esptool.py v4.7.0
Serial port /dev/ttyACM1
Connecting...
Chip is ESP32-S3 (QFN56) (revision v0.2)
Features: WiFi, BLE, Embedded PSRAM 8MB (AP_3v3)
Crystal is 40MHz
MAC: 10:20:ba:03:9c:b4
Uploading stub...
Running stub...
Stub running...
Changing baud rate to 460800
Changed.
Configuring flash size...
Flash will be erased from 0x00000000 to 0x00003fff...
Flash will be erased from 0x00010000 to 0x00061fff...
Compressed 15104 bytes to 10430...
Wrote 15104 bytes (10430 compressed) at 0x00000000 in 0.2 seconds (effective 499.5 kbit/s)...
Hash of data verified.
Compressed 334128 bytes to 191627...
Wrote 334128 bytes (191627 compressed) at 0x00010000 in 2.4 seconds (effective 1113.6 kbit/s)...
Hash of data verified.

Leaving...
Hard resetting via RTS pin...

and u can check in serial-monitor that must be print 
[irap-recam] : firmware-version=1.0.0
repeatly every 100 miliseconds

6.this low level instruction finsihed let install the high level package

// Read this before installation of high-level package
1.u must pull a irap_docker folder to arduino-uno q by using adb shell u can use this command `adb push irap_docker /home/arduino/`
2.Before using the esp32-cam u must be disable hardware serial debugger of arduino-uno q by using `sudo bash patch_serial.sh` this file has been patch boot entry console to use another console debugging and that make allow u to can use /dev/ttyMSM0 to communicate with another hardware (esp32-cam)
3.After disabled hardware serial debugger u must `sudo bash set_wifi_and_remove_gretty.sh` to make using best performance signal of wifi adapter
4.Let build docker by using sudo bash docker_build.sh until success (this method need internet connection)
5.using command `sudo docker compose up -d` to start a docker compose of ros2_humble container
6.after started the compose you can use `sudo docker compose exec ros2_humble bash` to interactive the shell command on docker 
7.using `ros2 launch irap_recam irap_recam_launch.py` if every thing are connected and correctly that must show a output of framerate like this below
root@rmrc-10:~# ros2 launch irap_recam irap_recam_launch.py
am-1] [irap_recam] FPS: 10.1611 | FrameID: 65 | Size: 32764 | Resolution: 640x480 | Processing: 14ms | Serial latency: 171.978ms
[irap_recam-1] [irap_recam] FPS: 10.2353 | FrameID: 78 | Size: 32776 | Resolution: 640x480 | Processing: 16ms | Serial latency: 71.1457ms
[irap_recam-1] [irap_recam] FPS: 11.1214 | FrameID: 90 | Size: 32692 | Resolution: 640x480 | Processing: 15ms | Serial latency: 97.5478ms
[irap_recam-1] [irap_recam] FPS: 11.0852 | FrameID: 102 | Size: 33220 | Resolution: 640x480 | Processing: 15ms | Serial latency: 97.455ms
[irap_recam-1] [irap_recam] FPS: 11.1468 | FrameID: 114 | Size: 32200 | Resolution: 640x480 | Processing: 14ms | Serial latency: 90.3259ms
[irap_recam-1] [irap_recam] FPS: 11.1161 | FrameID: 126 | Size: 31543 | Resolution: 640x480 | Processing: 15ms | Serial latency: 88.0765ms


// more settings and additional about recam package

# irap_espcam_ros2_driver
## package_name : irap_recam

ROS2 node that receives streamed JPEG frames from an ESP32-CAM over a serial link, reassembles them, decodes them, and publishes the result as a ROS2 `sensor_msgs/Image` on `/recam/image_raw`.

## Overview
  
- Reconfiguration on rqt directly to esp32-cam
---
![rqt_reconfig](https://raw.githubusercontent.com/IRAP-Organization/irap_espcam_ros2_driver/refs/heads/main/res/543329938-659c9465-a19c-4e28-9193-fa1a96ef77cd.gif?token=GHSAT0AAAAAADUPS7EPHBJVN4TICMN7QTRC2L6N3JQ)

![rqt_reconfig](https://raw.githubusercontent.com/IRAP-Organization/irap_espcam_ros2_driver/refs/heads/main/res/543330759-e8355090-3169-493b-a8c1-39b1a118b21f.gif?token=GHSAT0AAAAAADUPS7EO7E7RWVTFN5Y6T3LQ2L6N2NA)

---


- Latency Test
---

![latency](https://github.com/IRAP-Organization/irap_espcam_ros2_driver/blob/main/res/543329847-62b87421-0384-44fe-b76e-9ae657ba1d1a.gif?raw=true)

---

- Latency Snapshot
<img width="640" height="480" alt="image" src="https://raw.githubusercontent.com/IRAP-Organization/irap_espcam_ros2_driver/refs/heads/main/res/543328950-6cbc1027-7fd1-456b-8818-4a9dbbde434d.png?token=GHSAT0AAAAAADUPS7EPDWPG3H6HVZCRBIBU2L6NSSA" />
<img width="640" height="480" alt="image" src="https://raw.githubusercontent.com/IRAP-Organization/irap_espcam_ros2_driver/refs/heads/main/res/20260201_030449(1).jpg?token=GHSAT0AAAAAADUPS7EOU66MWN7EBWRBEUBQ2L6NZDQ" />



---

## System Design

```
low level (esp32_cam)              irap_recam (this node)
──────────                         ──────────────────────
capture iamge                       CallbackAsyncSerial (P-Aun Serial)
  │                                   │  (Boost.Asio, ASync Send/Receive)
  ├─ split into chunks                │
  ├─ pack data: [Image Chunk]         ▼
  │                                   received()   ← serial callback
  │                                   │  - validate framing
  └─► serial TX ─────────────────────►│  - reassemble chunks
                                      │  - queue complete frame
                                      ▼
                                   processingThreadFunc()  ← seperate thread for decode image
                                      │  - imdecode JPEG
                                      │  - resize if needed
                                      │  - invoke FrameCallback
                                      ▼
                                   onNewFrame()            ← callback on new frame and publish to outside
                                      │  - cv_bridge → sensor_msgs/Image
                                      │  - publish /recam/image_raw
                                      ▼
                                   rqt / any subscriber
```

---

## Serial Dataframe Layout

```
Offset   Size    Field
──────   ────    ─────
 0       1       START_BYTE  '#'  (0x23)
 1       4       frameId     (big-endian uint32) // for confirm the sequenceof frame
 5       2       chunkNum    (big-endian uint16) // current chunk number
 7       2       totalChunks (big-endian uint16) // total chunk
 9       2       dataControl (big-endian uint16, bit-flags) // for checking latency and confirm settings
11       8       reserved
19       2       dataLen     (big-endian uint16, payload byte count) // all data len
21       1       frameSize   (FrameSize enum, matches ESP32-CAM) // image resolution sync with low level
──────   ────    ─────────────────────────────────────────────────
22       N       JPEG payload (dataLen bytes) // image payload
22+N     1       END_BYTE    '\b' (0x08) // ending frame
```

Total packet = 22 (header) + dataLen + 1 (trailer).

---

## Camera Settings

Settings are pushed to the ESP32-CAM over the same serial link via a handshake:

1. low level flipbit on `dataControl_tx.bit0 = 1`, starts sending the settings packet every capture cycle.
2. low level acknowledges by clearing `dataControl_rx.bit2`.
3. low level `dataControl_tx.bit2 = 0`, handshake complete.

All values are configurable as ROS2 parameters at runtime (see [Parameters](#parameters)).

| Parameter        | Range   | Default | ESP32 mapping                     |
|------------------|---------|---------|-----------------------------------|
| `cam_resolution` | 1–21    | 8 (VGA) | `FrameSize` enum index            |
| `cam_quality`    | 1–63    | 15      | JPEG quality (lower = better)     |
| `cam_brightness` | −3 – 3  | 3       | Sent as `value − 3`               |
| `cam_contrast`   | −3 – 3  | 3       | Sent as `value − 3`               |
| `cam_saturation` | −4 – 4  | 4       | Sent as `value − 4`               |
| `cam_exposure`   | −4 – 4  | 4       | Sent as `value − 5`               |

Resolution Enum 
```
static const Resolution resolutions[] = {
        {96, 96},     // FRAMESIZE_96X96 = 0
        {160, 120},   // FRAMESIZE_QQVGA = 1
        {176, 144},   // FRAMESIZE_QCIF = 2
        {240, 176},   // FRAMESIZE_HQVGA = 3
        {240, 240},   // FRAMESIZE_240X240 = 4 
        {320, 240},   // FRAMESIZE_QVGA  = 5
        {400, 296},   // FRAMESIZE_CIF = 6
        {480, 320},   // FRAMESIZE_HVGA = 7
        {640, 480},   // FRAMESIZE_VGA = 8 
        {800, 600},   // FRAMESIZE_SVGA = 9
        {1024, 768},  // FRAMESIZE_XGA = 10
        {1280, 720},  // FRAMESIZE_HD = 11
        {1280, 1024}, // FRAMESIZE_SXGA = 12
        {1600, 1200}, // FRAMESIZE_UXGA  = 13
        {1920, 1080}, // FRAMESIZE_FHD = 14
        {720, 1280},  // FRAMESIZE_P_HD = 15
        {864, 1536},  // FRAMESIZE_P_3MP = 16
        {2048, 1536}, // FRAMESIZE_QXGA  = 17
        {2560, 1440}, // FRAMESIZE_QHD = 18
        {2560, 1600}, // FRAMESIZE_WQXGA = 19
        {1080, 1920}, // FRAMESIZE_P_FHD = 20 
        {2560, 1920}, // FRAMESIZE_QSXGA = 21
        {0, 0}        // FRAMESIZE_INVALID = 22 (u can't set)
    };
```

Change any parameter at runtime without restarting:

```bash
ros2 param set /irap_recam cam_quality 25
ros2 param set /irap_recam cam_resolution 5   # QVGA 320×240
```

---

## Parameters

| Parameter  | Type   | Default        | Description                          |
|------------|--------|----------------|--------------------------------------|
| `device`   | string | `/dev/ttyACM0` | Serial device path                   |
| `baudrate` | int    | 1000000        | Serial baud rate (minimum 9600)      |

---

## Prerequisites

### System

- **Ubuntu 22.04** (tested; other 22.04-based distros should work)
- **ROS2 Humble** (`humble`)
- C++17 capable compiler (`g++ ≥ 11`)

### ROS2 Packages

```bash
sudo apt update && sudo apt install -y \
    ros-humble-rclcpp \
    ros-humble-std-msgs \
    ros-humble-sensor-msgs \
    ros-humble-image-transport \
    ros-humble-cv-bridge \
    ros-humble-image-view
```

### System Libraries

```bash
sudo apt install -y \
    libboost-all-dev \
    libopencv-dev
```

---

## Build

```bash
# Source ROS2 if not already done
source /opt/ros/humble/setup.bash

# Clone (or place this package inside your colcon workspace src/)
mkdir -p ~/ros2_ws/src
cd ~/ros2_ws/src
git clone <this repo>

# Build
cd ~/ros2_ws
colcon build --packages-select irap_recam

# Source the result
source install/setup.bash
```

---

## Run

**Before running if you got a error about permission u must be `sudo chmod 777 /dev/ttyUSB0` or your usb path to grant the permission **

```bash
ros2 run irap_recam irap_recam
```

Override defaults via command-line arguments:

```bash
ros2 run irap_recam irap_recam --ros-args \
    -p device:=/dev/ttyUSB0 \
    -p baudrate:=1000000
```

---

Fast Run you can using launch file for this package 

**U MUST CHANGE SERIAL DEVICE PATH AND BAUDRATE BEFORE LAUNCH **
```
    device_arg = DeclareLaunchArgument(
        'device',
        default_value='/dev/ttyACM0',
        description='Serial device path'
    )

    baudrate_arg = DeclareLaunchArgument(
        'baudrate',
        default_value='1000000',
        description='Serial baudrate'
    )

```
```bash
ros2 launch irap_recam irap_recam_launch.py
```

## View the Stream

```bash
# GUI image viewer
ros2 run image_view image_view --ros-args -r image:=/recam/image_raw

# Or rqt
rqt_image_view
```

---

## Console Output

While running, the node prints a stats line once per second:

```
FPS: 44.2 | FrameID: 1042 | Size: 18765 | Resolution: 640x480 | Processing: 1ms | Serial latency: 49.3ms
```

| Field            | Meaning                                                      |
|------------------|--------------------------------------------------------------|
| FPS              | Decoded frames per second                                    |
| FrameID          | Last completed frame sequence number from ESP32              |
| Size             | Raw JPEG size in bytes before decoding                       |
| Resolution       | Decoded image dimensions                                     |
| Processing       | Time from "last chunk received" to "frame published" (ms)    |
| Serial latency   | Round-trip measured via the `dataControl` bit handshake (ms) |

---

## Latency Test

End-to-end latency at 640×480 / 1 Mbaud is typically **50–70 ms**, broken down roughly as:

| Stage                              | Typical    |
|------------------------------------|------------|
| ESP32 capture + chunk + transmit   | 40–60 ms   |
| Serial reassembly (this node)      | < 1 ms     |
| JPEG decode + resize               | 1–5 ms     |
| ROS2 publish overhead              | 1–3 ms     |

The serial receive path (`received()`) only parses headers and queues complete frames. All heavy work (JPEG decode, resize, callback) runs on a separate `processingThread`, keeping the Boost.Asio serial thread unblocked.

---
