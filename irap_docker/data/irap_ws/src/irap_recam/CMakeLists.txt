cmake_minimum_required(VERSION 3.8)
project(irap_recam)

# ── Dependencies ──
find_package(ament_cmake REQUIRED)
find_package(rclcpp REQUIRED)
find_package(sensor_msgs REQUIRED)
find_package(std_msgs REQUIRED)
find_package(image_transport REQUIRED)
find_package(cv_bridge REQUIRED)
find_package(OpenCV REQUIRED)

# ── Prebuilt binary ──
set(PREBUILT_BINARY "${CMAKE_CURRENT_SOURCE_DIR}/prebuilt/irap_recam")

if(NOT EXISTS "${PREBUILT_BINARY}")
  message(FATAL_ERROR
    "\n[irap_recam] Prebuilt binary not found at:\n"
    "  ${PREBUILT_BINARY}\n")
endif()

file(CHMOD "${PREBUILT_BINARY}"
  PERMISSIONS
    OWNER_READ OWNER_WRITE OWNER_EXECUTE
    GROUP_READ GROUP_EXECUTE
    WORLD_READ WORLD_EXECUTE
)

install(
  PROGRAMS "${PREBUILT_BINARY}"
  DESTINATION lib/${PROJECT_NAME}
)

# ── Launch files ──
install(DIRECTORY launch/
  DESTINATION share/${PROJECT_NAME}/launch
)

ament_package()

