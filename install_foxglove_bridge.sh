#!/bin/bash

ROS_INSTALL_ROOT="/opt/ros/ros2_rolling"

rm -Rf $ROS_INSTALL_ROOT/src/ros-foxglove-bridge $ROS_INSTALL_ROOT/build/foxglove_bridge $ROS_INSTALL_ROOT/install/foxglove_bridge

echo "Installing Foxglove bridge dependencies via brew"

brew install websocketpp boost nlohmann-json

echo "Cloning Foxglove bridge repo"

git clone https://github.com/foxglove/ros-foxglove-bridge.git $ROS_INSTALL_ROOT/src/ros-foxglove-bridge

export COLCON_EXTENSION_BLOCKLIST=colcon_core.event_handler.desktop_notification

PATH_TO_QT5="/opt/homebrew/opt/qt@5"                    
export CMAKE_PREFIX_PATH=${CMAKE_PREFIX_PATH}:${PATH_TO_QT5}
export PATH=$PATH:${PATH_TO_QT5}/bin
export CMAKE_PREFIX_PATH=/opt/homebrew/opt:$CMAKE_PREFIX_PATH

SCRIPTDIR=`pwd`

(
    cd $ROS_INSTALL_ROOT

    echo "Activating ROS workspace"

    . "$ROS_INSTALL_ROOT/../python_venv/bin/activate"

    cd install

    . "./setup.bash"

    cd ..

    echo "Patching Foxglove bridge CMakeLists"

    patch < "$SCRIPTDIR/patches/foxglove_cmakelists.patch"

    echo "Patching Foxglove parameters interface"

    patch < "$SCRIPTDIR/patches/foxglove_parameter_interface.patch"

    echo "Patching Foxglove bridge"

    patch < "$SCRIPTDIR/patches/foxglove_bridge.patch"

    echo "Running build"

    colcon build --symlink-install --cmake-args -DBUILD_TESTING=OFF -DUSE_ASIO_STANDALONE=OFF -DCMAKE_CXX_FLAGS="-Wno-error=old-style-cast -Wno-error=null-pointer-subtraction -Wno-old-style-cast -Wno-deprecated-declarations -w" --packages-select foxglove_bridge
)

echo "See https://foxglove.dev/docs/studio/connection/using-foxglove-bridge on instructions to run the bridge"
