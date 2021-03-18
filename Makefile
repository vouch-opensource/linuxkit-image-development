# Instances
REMOTE_USER := ubuntu
AWS_REGION := us-east-1
PROJECT := linuxkit-image-development
HOST = $(shell cat /tmp/lxk-build-machine-ip-address)
INSTANCE_ID = $(shell cat /tmp/lxk-instance-id)
AMI_NAME := linuxkit-image
OUTPUT_FILE := image.raw
BUILD_INSTANCE_NAME := linuxkit-build
LINUXKIT_INSTANCE_NAME ?=
LINUXKIT_BUCKET ?=
FILE ?=

# Registry
USERNAME ?=
PASSWORD ?=
URL := registry.hub.docker.com

build:
	linuxkit build -format aws -size 2048M -name $(OUTPUT_FILE) $(FILE)

push:
	linuxkit -v push aws -ena -timeout 3600 -bucket ${LINUXKIT_BUCKET} -img-name $(AMI_NAME)-$(shell date +"%Y%m%d%H%M%S" -u) $(OUTPUT_FILE)

build-machine-ip-address:
	@aws ec2 describe-instances --query "Reservations[*].Instances[*].PublicIpAddress" \
                               --filters 'Name=tag:Name,Values=$(BUILD_INSTANCE_NAME)' 'Name=instance-state-name,Values=running' \
                               | grep -E -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}" > /tmp/lxk-build-machine-ip-address

linuxkit-instance-id:
	@aws ec2 describe-instances --query "Reservations[*].Instances[*].InstanceId" \
                              --filters 'Name=tag:Name,Values=$(LINUXKIT_INSTANCE_NAME)' 'Name=instance-state-name,Values=running' \
                              | grep -E -o "i\-[[:alnum:]]+" > /tmp/lxk-instance-id

remote-docker-login: build-machine-ip-address
	@ssh ${REMOTE_USER}@${HOST} "docker login ${URL} -u ${USERNAME} -p ${PASSWORD}"

remote-sync: build-machine-ip-address
	rsync -azvp --exclude-from='.rsyncignore' . ${REMOTE_USER}@${HOST}:~/${PROJECT}

remote-build: remote-sync
	ssh ${REMOTE_USER}@${HOST} "make -C ${PROJECT} build FILE=$(FILE)"

remote-update-image: linuxkit-instance-id
	ssh ${REMOTE_USER}@${HOST} "AWS_DEFAULT_REGION=${AWS_REGION} update-image.sh ${PROJECT}/sync/${FILE} ${INSTANCE_ID}"

remote-push: remote-sync
	ssh ${REMOTE_USER}@${HOST} "source /etc/profile && AWS_REGION=${AWS_REGION} make -C ${PROJECT} push"

remote-deploy: remote-build remote-update-image
