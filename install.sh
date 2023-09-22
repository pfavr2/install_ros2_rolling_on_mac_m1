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
  pyqt5 python qt@5 sip spdlog tinyxml tinyxml2

# Setup paths
export OPENSSL_ROOT_DIR=$(brew --prefix openssl@3)
PATH_TO_QT5="/opt/homebrew/opt/qt@5"
export CMAKE_PREFIX_PATH=${CMAKE_PREFIX_PATH}:${PATH_TO_QT5}
export PATH=$PATH:${PATH_TO_QT5}/bin
export CMAKE_PREFIX_PATH=/opt/homebrew/opt:$CMAKE_PREFIX_PATH

# Disable notification error on mac
export COLCON_EXTENSION_BLOCKLIST=colcon_core.event_handler.desktop_notification

# Make Python virtual environment
python3 -m venv python_venv

source python_venv/bin/activate

python3 -m pip install -U \
  argcomplete catkin_pkg colcon-common-extensions coverage \
  cryptography empy flake8 flake8-blind-except==0.1.1 flake8-builtins \
  flake8-class-newline flake8-comprehensions flake8-deprecated \
  flake8-docstrings flake8-import-order flake8-quotes \
  importlib-metadata jsonschema lark==1.1.1 lxml matplotlib mock mypy==0.931 netifaces \
  nose pep8 psutil pydocstyle pydot pyparsing==2.4.7 \
  pytest-mock rosdep rosdistro setuptools==59.6.0 vcstool

#(
#  CFLAGS="-I/opt/homebrew/Cellar/graphviz/8.0.5/include"
#  LDFLAGS="-L/opt/homebrew/Cellar/graphviz/8.0.5/lib"
#  python3 -m pip install -U pygraphviz
#)

python3 -m pip install \
  --global-option=build_ext \
  --global-option="-I$(brew --prefix graphviz)/include/" \
  --global-option="-L$(brew --prefix graphviz)/lib/" \
    pygraphviz

python3 -m pip install --upgrade pip

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
patch < "$SCRIPT_DIR/patches/ros2_rviz_visual_testing_framework_include_directories_qt5.15.10.patch"
patch < "$SCRIPT_DIR/patches/ros2_rviz_rendering_include_directories_qt5.15.10.patch"
patch < "$SCRIPT_DIR/patches/ros2_rviz_default_plugins_include_directories_qt5.15.10.patch"
patch < "$SCRIPT_DIR/patches/ros2_rviz_common_include_directories_qt5.15.10.patch"
patch < "$SCRIPT_DIR/patches/ros2_mimic_vendor_vcs_version.patch"
patch < "$SCRIPT_DIR/patches/ros2_rviz2_include_directories_qt5.15.10.patch"

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
