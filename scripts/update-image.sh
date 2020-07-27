#!/usr/bin/env bash

set -ex

image=$1
instance=$2
volume=$(tm-machine.clj get-volume $instance "/dev/sda1")

linuxkit build -format aws $1
tm-machine.clj stop $instance $volume
result_image=$(echo $image | sed 's/yml/raw/')
sudo dd if=$result_image of=/dev/nvme1n1 bs=64k # todo: automatically detect /dev/nvme1 device name.
tm-machine.clj start $instance $volume
