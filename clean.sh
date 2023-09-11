#!/bin/bash

if typeset -f deactivate_ros > /dev/null; then
  deactivate_ros
fi

sudo rm -Rf /opt/ros/

