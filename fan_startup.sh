#!/bin/bash

set -x
exec > /tmp/gpu-fan.log 2>&1

nvidia-settings -a [gpu:0]/GPUFanControlState=1 2> /dev/null >> /dev/null
nvidia-settings -a [fan:0]/GPUTargetFanSpeed=100 2> /dev/null >> /dev/null
nvidia-settings -a [fan:1]/GPUTargetFanSpeed=100 2> /dev/null >> /dev/null 
