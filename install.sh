#!/bin/zsh


###################################
# Configuration
###################################
# ROS_DISTRO="ros2_rolling" # Not used
ROS_INSTALL_ROOT="/opt/ros/"


###################################
# Helper functions
###################################
function error() {
  echo "$@"
  exit -1
}

SCRIPT_DIR=${0:a:h}


###################################
# Checking for existing installation
###################################
if [ ! -z "$(ls -A "$ROS_INSTALL_ROOT" 2&> /dev/null)" ]; then
  echo "Installation already exist."
  echo "If you want to do a reinstallation run:"
  echo "  $(dirname $0)/clean.sh && $0"
  error
fi

sudo mkdir -p "$ROS_INSTALL_ROOT"
sudo chown -R $USER: "$ROS_INSTALL_ROOT"
pushd "$ROS_INSTALL_ROOT"


###################################
# Making sure Xcode is installed
###################################
if [ ! -e "/Applications/Xcode.app/Contents/Developer" ]; then
  error "Please install Xcode through the App Store"
fi

if [ "$(xcode-select -p)" != "/Applications/Xcode.app/Contents/Developer" ]; then
  echo "Changing the xcode path"
  sudo xcode-select -s "/Applications/Xcode.app/Contents/Developer"
  XCODE_VERSION=`xcodebuild -version | grep '^Xcode\s' | sed -E 's/^Xcode[[:space:]]+([0-9\.]+)/\1/'`
  ACCEPTED_LICENSE_VERSION=`defaults read /Library/Preferences/com.apple.dt.Xcode 2> /dev/null | grep IDEXcodeVersionForAgreedToGMLicense | cut -d '"' -f 2`

  if [ "$XCODE_VERSION" != "$ACCEPTED_LICENSE_VERSION" ]; then
    echo "Xcode license needs to be accepted"
    sudo xcodebuild -license
    if [ $? -ne 0 ]; then
      error "Failed to accept license"
    fi
  fi
fi

###################################
# Making sure brew is installed
###################################
echo "Checking if brew is installed"
which brew > /dev/null
if [ $? -ne 0 ]; then
  echo "Installing brew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi


###################################
# Installing ROS2 dependencies
###################################
brew install asio assimp bison bullet cmake console_bridge cppcheck \
  cunit eigen freetype graphviz opencv openssl orocos-kdl pcre poco \
  pyqt5 python@3.11 qt@5 sip spdlog tinyxml tinyxml2

# Setup paths
export OPENSSL_ROOT_DIR=$(brew --prefix openssl@3)
PATH_TO_QT5="/opt/homebrew/opt/qt@5"
export CMAKE_PREFIX_PATH=${CMAKE_PREFIX_PATH}:${PATH_TO_QT5}
export PATH=$PATH:${PATH_TO_QT5}/bin
export CMAKE_PREFIX_PATH=/opt/homebrew/opt:$CMAKE_PREFIX_PATH

# Disable notification error on mac
export COLCON_EXTENSION_BLOCKLIST=colcon_core.event_handler.desktop_notification

# Make Python virtual environment
python3.11 -m venv python_venv

source python_venv/bin/activate

python3 -m pip install -U \
  argcomplete catkin_pkg colcon-common-extensions coverage \
  cryptography empy flake8 flake8-blind-except==0.1.1 flake8-builtins \
  flake8-class-newline flake8-comprehensions flake8-deprecated \
  flake8-docstrings flake8-import-order flake8-quotes \
  importlib-metadata jsonschema lark==1.1.1 lxml matplotlib mock mypy==0.931 netifaces \
  nose pep8 psutil pydocstyle pydot pyparsing==2.4.7 \
  pytest-mock rosdep rosdistro setuptools==59.6.0 vcstool

python3 -m pip install \
  --config-settings="--global-option=build_ext" \
  --config-settings="--global-option=-I/opt/homebrew/opt/graphviz/include/" \
  --config-settings="--global-option=-L/opt/homebrew/opt/graphviz/lib/" \
    pygraphviz

python3 -m pip install --upgrade pip

## Check if Python3.12 is installed (currently does not work):
if brew list --formula | grep -q "python@3.12"; then
  echo "Python@3.12 is installed. Currently this does not work."
  echo "Please uninstall using:"
  echo
  echo "brew uninstall --ignore-dependencies python@3.12"
  echo
  echo "then run ./clean.sh; ./install.sh"
  exit(1)
fi

patch < "$SCRIPT_DIR/patches/python_setuptools_easy_install.patch"
patch < "$SCRIPT_DIR/patches/python_setuptools_install.patch"

mkdir -p ros2_rolling/src
cd ros2_rolling
vcs import --input https://raw.githubusercontent.com/ros2/ros2/rolling/ros2.repos src

colcon build --symlink-install  --cmake-args -DBUILD_TESTING=OFF -Wno-dev --packages-skip-by-dep python_qt_binding --packages-up-to cyclonedds

ln -s "../../iceoryx_posh/lib/libiceoryx_posh.dylib" install/iceoryx_binding_c/lib/libiceoryx_posh.dylib
ln -s "../../iceoryx_hoofs/lib/libiceoryx_hoofs.dylib" install/iceoryx_binding_c/lib/libiceoryx_hoofs.dylib
ln -s "../../iceoryx_hoofs/lib/libiceoryx_platform.dylib" install/iceoryx_binding_c/lib/libiceoryx_platform.dylib

patch < "$SCRIPT_DIR/patches/ros2_tf2_eigen_kdl.patch"
patch < "$SCRIPT_DIR/patches/ros2_interactive_markers.patch"
patch < "$SCRIPT_DIR/patches/ros2_rviz_ogre_vendor.patch"
patch < "$SCRIPT_DIR/patches/ros2_rviz_default_plugins_include_directories.patch"
patch < "$SCRIPT_DIR/patches/ros2_kdl_parser_orocos-kdl_include_directories.patch"
patch < "$SCRIPT_DIR/patches/ros2_rosbag2_transport_uint64_t.patch"
#patch < "$SCRIPT_DIR/patches/ros2_point_cloud_transport_smartpointer.patch"

( cd ./src/ros2/orocos_kdl_vendor/python_orocos_kdl_vendor; git checkout 0.4.1 )

colcon build --symlink-install --cmake-args -DBUILD_TESTING=OFF -Wno-dev --packages-skip-by-dep python_qt_binding

#colcon build \
#  --symlink-install \
#  --merge-install \
#  --packages-skip-by-dep python_qt_binding \
#  --cmake-args \
#    --no-warn-unused-cli \
#    -DBUILD_TESTING=OFF \
#    -DINSTALL_EXAMPLES=ON \
#    -DCMAKE_OSX_SYSROOT=/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk \
#    -DCMAKE_OSX_ARCHITECTURES="arm64" \
#    -DCMAKE_PREFIX_PATH=$(brew --prefix qt@5):$(brew --prefix)

cp "$SCRIPT_DIR/setenv.sh" "$ROS_INSTALL_ROOT/activate_ros"

echo "Done."
echo
echo "To activate the new ROS2 distribution run the following command:"
echo ". ${ROS_INSTALL_ROOT}activate_ros"
echo
echo "To deactivate this workspace, run:"
echo "deactivate_ros"

popd

unset -f error
