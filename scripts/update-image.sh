#!/usr/bin/env bash

set -ex

image=$1
instance=$2
volume=$(lxk-machine.clj get-volume $instance "/dev/sda1")

tm-machine.clj stop $instance $volume
sudo dd if=$image of=/dev/nvme1n1 bs=64k # todo: automatically detect /dev/nvme1 device name.
tm-machine.clj start $instance $volume
