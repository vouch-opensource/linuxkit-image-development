#!/bin/bash

set -ex

apt-get update
apt-get remove docker docker-engine docker.io containerd runc
apt-get install -y golang-go git awscli unzip
apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg-agent \
    software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
apt-key fingerprint 0EBFCD88
add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"
apt-get update
apt-get -y install docker-ce docker-ce-cli containerd.io qemu
usermod -a -G docker ubuntu

# install linuxkit
export GOPATH=~/go
mkdir -p $GOPATH
go get -u github.com/linuxkit/linuxkit/src/cmd/linuxkit
cp $GOPATH/bin/linuxkit /usr/local/bin/

# install babashka
curl -s https://raw.githubusercontent.com/borkdude/babashka/master/install -o install-babashka
chmod +x install-babashka
./install-babashka

git clone https://github.com/vouch-opensource/linuxkit-image-development.git
cp linuxkit-image-development/scripts/* /usr/local/bin/
