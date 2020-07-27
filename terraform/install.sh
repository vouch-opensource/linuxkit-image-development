#!/bin/bash

set -ex

apt-get update
apt-get install -y docker golang-go git awscli curl unzip

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
