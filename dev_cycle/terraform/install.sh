#!/bin/bash

set -ex

# dependenciess

apt-get update
apt-get remove docker docker-engine docker.io containerd runc
apt-get install -y golang-go git awscli unzip
apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg-agent \
    make \
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
go get github.com/linuxkit/linuxkit/src/cmd/linuxkit
pushd $GOPATH/src/github.com/linuxkit/linuxkit
git checkout ${linuxkit_version}
make local-build
popd
cp $GOPATH/src/github.com/linuxkit/linuxkit/bin/linuxkit /usr/local/bin/
chmod +x /usr/local/bin/linuxkit

# install babashka

curl -s https://raw.githubusercontent.com/borkdude/babashka/${babashka_version}/install -o install-babashka
chmod +x install-babashka
./install-babashka

git clone https://github.com/vouch-opensource/linuxkit-image-development.git
cp linuxkit-image-development/dev_cycle/scripts/* /usr/local/bin/
