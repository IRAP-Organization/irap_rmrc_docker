FROM ros:humble-ros-core

ENV DEBIAN_FRONTEND=noninteractive
ENV WORKSPACE=/opt/ros2_dep_ws

# ── System dependencies ──────────────────────────────────────────────────────
RUN apt-get update && apt-get install -y \
  net-tools \
  nano \
  python3-pip \
  python3-dev \
  python3-colcon-common-extensions \
  python3-rosdep \
  python3-setuptools \
  python3-wheel \
  build-essential \
  cmake \
  git \
  wget \
  curl \
  vim \
  libboost-all-dev \
  libopencv-dev \
  libyaml-cpp-dev \
  libtinyxml2-dev \
  libconsole-bridge-dev \
  libboost-system-dev \
  libboost-thread-dev \
  gpiod \
  libgpiod-dev \
  libgpiod2 \
  python3-libgpiod \
  && rm -rf /var/lib/apt/lists/*

# ── pip fix: create all common symlinks ─────────────────────────────────────
RUN ln -sf /usr/bin/pip3 /usr/bin/pip && \
    ln -sf /usr/bin/pip3 /usr/local/bin/pip && \
    ln -sf /usr/bin/pip3 /usr/local/bin/pip3 && \
    ln -sf /usr/bin/python3 /usr/bin/python && \
    ln -sf /usr/bin/python3 /usr/local/bin/python && \
    ln -sf /usr/bin/python3 /usr/local/bin/python3

# ── Upgrade pip itself ───────────────────────────────────────────────────────
RUN pip3 install --no-cache-dir --upgrade pip setuptools wheel

# ── Python packages ──────────────────────────────────────────────────────────
RUN pip install --no-cache-dir \
  msgpack \
  packaging \
  catkin_pkg \
  colcon-common-extensions \
  argcomplete \
  lark \
  netifaces \
  numpy \
  PyYAML \
  pyserial \
  gpiod

# ── rosdep ───────────────────────────────────────────────────────────────────
RUN rosdep init && rosdep update

# ── Workspace dir ─────────────────────────────────────────────────────────────
RUN mkdir -p ${WORKSPACE}
WORKDIR ${WORKSPACE}

# ── Clone ros2_dep_ws ─────────────────────────────────────────────────────────
RUN /bin/bash -c "\
  source /opt/ros/humble/setup.bash && \
  mkdir -p ${WORKSPACE}/src && \
  cd ${WORKSPACE}/src && \
  git clone https://github.com/ros2/message_filters.git -b humble && \
  git clone https://github.com/ros-perception/image_common.git -b humble && \
  git clone https://github.com/ros-perception/vision_opencv.git -b humble && \
  git clone https://github.com/ros2/yaml_cpp_vendor.git -b humble && \
  git clone https://github.com/ros2/console_bridge_vendor.git -b humble && \
  git clone https://github.com/ros2/tinyxml2_vendor.git -b humble && \
  git clone https://github.com/ros/pluginlib.git -b humble && \
  git clone https://github.com/ros/class_loader.git -b humble"

# ── Fix cv_bridge header install path ────────────────────────────────────────
RUN sed -i \
  's|install(DIRECTORY include/ DESTINATION include/${PROJECT_NAME})|install(DIRECTORY include/ DESTINATION include)|' \
  ${WORKSPACE}/src/vision_opencv/cv_bridge/CMakeLists.txt

# ── Fix cv_bridge src/CMakeLists.txt ─────────────────────────────────────────
RUN printf '%s\n' \
  'include(GenerateExportHeader)' \
  'add_library(cv_bridge cv_bridge.cpp rgb_colors.cpp)' \
  'generate_export_header(cv_bridge' \
  '  EXPORT_FILE_NAME cv_bridge/cv_bridge_export.h)' \
  'target_include_directories(cv_bridge PUBLIC' \
  '  $<BUILD_INTERFACE:${CMAKE_SOURCE_DIR}/include>' \
  '  $<BUILD_INTERFACE:${CMAKE_CURRENT_BINARY_DIR}>' \
  '  $<INSTALL_INTERFACE:include>)' \
  'ament_target_dependencies(cv_bridge rcpputils sensor_msgs OpenCV)' \
  'install(TARGETS cv_bridge EXPORT export_cv_bridge' \
  '  ARCHIVE DESTINATION lib LIBRARY DESTINATION lib RUNTIME DESTINATION bin)' \
  'install(FILES ${CMAKE_CURRENT_BINARY_DIR}/cv_bridge/cv_bridge_export.h' \
  '  DESTINATION include/cv_bridge)' \
  > ${WORKSPACE}/src/vision_opencv/cv_bridge/src/CMakeLists.txt

# ── Build ros2_dep_ws (baked into image at /opt/ros2_dep_ws) ─────────────────
RUN /bin/bash -c "\
  source /opt/ros/humble/setup.bash && \
  cd ${WORKSPACE} && \
  for pkg in yaml_cpp_vendor console_bridge_vendor tinyxml2_vendor \
              class_loader pluginlib message_filters \
              camera_calibration_parsers camera_info_manager \
              image_transport cv_bridge; do \
    echo '======= Building' \$pkg '=======' && \
    MAKEFLAGS='-j2' colcon build \
      --symlink-install \
      --packages-select \$pkg \
      --parallel-workers 1 \
      --executor sequential \
      --cmake-args -DBUILD_TESTING=OFF -Wno-dev && \
    source install/setup.bash; \
  done"

# ── Permanent environment ─────────────────────────────────────────────────────
RUN echo "source /opt/ros/humble/setup.bash" >> ~/.bashrc && \
    echo "source ${WORKSPACE}/install/setup.bash" >> ~/.bashrc && \
    echo "[ -f /home/arduino/ros2_humble/data/irap_ws/install/setup.bash ] && source /home/arduino/ros2_humble/data/irap_ws/install/setup.bash" >> ~/.bashrc && \
    echo "export PATH=\$PATH:/usr/local/bin" >> ~/.bashrc

RUN apt-get update && apt-get install -y \
    ros-humble-image-transport-plugins

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["bash"]
