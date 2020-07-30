#!/usr/bin/env bash

set -ex

image=$1
instance=$2
disk=${3:-/dev/nvme1n1}
volume=$(lxk-machine.clj get-volume $instance "/dev/sda1")

tm-machine.clj stop $instance $volume

while [[ ! -b $disk && $retries -le 5 ]]; do
    sleep 1;
    retries=$(( $retries + 1 ))
done

if [[ -b $disk ]]; then
    sudo dd if=$image of=$disk bs=64k
else
    echo "Couldn't find disk $disk"
    exit 1
fi

tm-machine.clj start $instance $volume
