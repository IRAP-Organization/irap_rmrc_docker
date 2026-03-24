#!/bin/bash
set -e

# ── Hardware setup ────────────────────────────────────────────────────────────
chmod 777 /dev/ttyHS1 2>/dev/null || true

# ── Start arduino-router in background ───────────────────────────────────────
/usr/bin/arduino-router --unix-port /var/run/arduino-router.sock &

# ── Source ROS2 base ──────────────────────────────────────────────────────────
source /opt/ros/humble/setup.bash

# ── ros2_dep_ws: pre-built in image ──────────────────────────────────────────
echo "[entrypoint] Sourcing pre-built ros2_dep_ws (image)..."
source /opt/ros2_dep_ws/install/setup.bash

# ── /home/arduino/ros2_dep_ws: build if src exists, then source ──────────────
ARDUINO_DEP_WS=/home/arduino/ros2_dep_ws
if [ -d "${ARDUINO_DEP_WS}/src" ]; then
  echo "[entrypoint] Building /home/arduino/ros2_dep_ws..."
  cd "${ARDUINO_DEP_WS}"
  MAKEFLAGS='-j2' colcon build \
    --symlink-install \
    --parallel-workers 1 \
    --executor sequential \
    --cmake-args -DBUILD_TESTING=OFF -Wno-dev
  echo "[entrypoint] /home/arduino/ros2_dep_ws build done."
fi
if [ -f "${ARDUINO_DEP_WS}/install/setup.bash" ]; then
  echo "[entrypoint] Sourcing /home/arduino/ros2_dep_ws..."
  source "${ARDUINO_DEP_WS}/install/setup.bash"
  # Append to bashrc if not already there
  grep -qxF "source ${ARDUINO_DEP_WS}/install/setup.bash" ~/.bashrc || \
    echo "source ${ARDUINO_DEP_WS}/install/setup.bash" >> ~/.bashrc
else
  echo "[entrypoint] /home/arduino/ros2_dep_ws not found, skipping."
fi

# ── /home/arduino/irap_ws: build if src exists, then source ──────────────────
IRAP_WS=/home/arduino/irap_ws
if [ -d "${IRAP_WS}/src" ]; then
  echo "[entrypoint] Building /home/arduino/irap_ws..."
  cd "${IRAP_WS}"
  MAKEFLAGS='-j2' colcon build \
    --symlink-install \
    --parallel-workers 1 \
    --executor sequential \
    --cmake-args -DBUILD_TESTING=OFF -Wno-dev
  echo "[entrypoint] /home/arduino/irap_ws build done."
fi
if [ -f "${IRAP_WS}/install/setup.bash" ]; then
  echo "[entrypoint] Sourcing /home/arduino/irap_ws..."
  source "${IRAP_WS}/install/setup.bash"
  # Append to bashrc if not already there
  grep -qxF "source ${IRAP_WS}/install/setup.bash" ~/.bashrc || \
    echo "source ${IRAP_WS}/install/setup.bash" >> ~/.bashrc
else
  echo "[entrypoint] /home/arduino/irap_ws not found, skipping."
fi

# ── irap_ws (legacy path): build if src exists, then source ──────────────────
LEGACY_IRAP_WS=/home/arduino/ros2_humble/data/irap_ws
if [ -d "${LEGACY_IRAP_WS}/src" ]; then
  echo "[entrypoint] Building legacy irap_ws..."
  cd "${LEGACY_IRAP_WS}"
  MAKEFLAGS='-j2' colcon build \
    --symlink-install \
    --parallel-workers 1 \
    --executor sequential \
    --cmake-args -DBUILD_TESTING=OFF -Wno-dev
  echo "[entrypoint] Legacy irap_ws build done."
fi
if [ -f "${LEGACY_IRAP_WS}/install/setup.bash" ]; then
  echo "[entrypoint] Sourcing legacy irap_ws..."
  source "${LEGACY_IRAP_WS}/install/setup.bash"
  grep -qxF "source ${LEGACY_IRAP_WS}/install/setup.bash" ~/.bashrc || \
    echo "source ${LEGACY_IRAP_WS}/install/setup.bash" >> ~/.bashrc
else
  echo "[entrypoint] Legacy irap_ws not found, skipping."
fi

# ── workspace_zone: source any built workspaces found inside ─────────────────
echo "[entrypoint] Scanning /workspace_zone for built workspaces..."
for ws_setup in /workspace_zone/*/install/setup.bash; do
  if [ -f "${ws_setup}" ]; then
    echo "[entrypoint] Sourcing ${ws_setup}..."
    source "${ws_setup}"
  fi
done

# ── Drop into shell ───────────────────────────────────────────────────────────
exec "$@"
