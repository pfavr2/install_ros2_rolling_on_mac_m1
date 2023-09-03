#!/bin/bash

#After running - you need to activate:

# Grab old environment
export OLD_ENV="$(export -p)"

# Clean current environment and restore old environment from before activating
function deactivate_ros() {
  if typeset -f deactivate > /dev/null; then
    deactivate
  fi
  for var in $(env | awk -F= '{print $1}' | grep -o '[^ ]*$'); do 
    if [ $var != "OLD_ENV" ]; then
      # echo "Removing var [$var]"
      unset $var
    fi
  done
  printf "$OLD_ENV" | source /dev/stdin
  unset OLD_ENV
  unset -f deactivate_ros
}

DIR="$(dirname $0)"

. "$DIR/python_venv/bin/activate"

. "$DIR/ros2_rolling/install/setup.zsh"
