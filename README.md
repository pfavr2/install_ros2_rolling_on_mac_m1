# install_ros2_rolling_on_mac_m1
Scripts and patches to install ros2_rolling on Mac M1

Confirmed to work on 2024-02-10 on MacOS Sonoma 14.3.1 (23D60).

On Apple M2 Pro with 32GB RAM: 334 packages finished [14min 43s]

## HOW TO

NOTE: XCode and HomeBrew should be installed before install.sh is run:

1. Start XCode once after installing to accept the license terms.
2. Ugrade brew packages to newest versions:
```brew upgrade```
4. Then run:
```./install.sh ```

The script builds almost everything.

Rviz2 is working also.

No need to change Apple SIP (system integrity protection).

On my Macbook Pro with M2 Pro cpu and 32GB RAM) it takes roughly 15 minutes:

```
...<snip>
Finished <<< rviz_common [2min 7s]                                   
Starting >>> rviz_visual_testing_framework
Finished <<< rviz_visual_testing_framework [15.4s]                                 
Starting >>> rviz_default_plugins
[Processing: rviz_default_plugins]                                       
[Processing: rviz_default_plugins]                                         
Finished <<< rviz_default_plugins [1min 3s]                                
Starting >>> rviz2              
Finished <<< rviz2 [14.4s]                                

Summary: 333 packages finished [14min 4s]
  30 packages had stderr output: cyclonedds demo_nodes_cpp fastcdr foonathan_memory_vendor gmock_vendor google_benchmark_vendor gtest_vendor iceoryx_binding_c iceoryx_hoofs iceoryx_posh pendulum_control rcl rcl_lifecycle rcl_logging_interface rcutils rmw rmw_connextdds_common rmw_cyclonedds_cpp rosbag2_performance_benchmarking rosbag2_performance_benchmarking_msgs rosbag2_storage_mcap rosbag2_transport rti_connext_dds_cmake_module rttest rviz_ogre_vendor tlsf tlsf_cpp uncrustify_vendor urdfdom_headers yaml_cpp_vendor
Done.
```

Please create an issue if you experience any problems.
