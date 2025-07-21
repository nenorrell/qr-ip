GIT_HASH=$(shell git rev-parse --short HEAD)
QP_IP_IMAGE=ghcr.io/nenorrell/qr-ip
TAG=latest
TARGET_PORT ?= 80
HOST_IP := $(shell .bin/find-host-ip.sh)
SERVING_PORT ?= 80

.PHONY: all build run tag deploy

build:
	docker buildx build -t $(QP_IP_IMAGE):$(GIT_HASH) .

push:
	docker push $(QP_IP_IMAGE):latest

tag: build
	docker tag $(QP_IP_IMAGE):$(GIT_HASH) $(QP_IP_IMAGE):latest

deploy: tag push

run:
	@echo "Using LAN IP: $(HOST_IP)"
	docker run --rm -it --init \
		-e HOST_IP=$(HOST_IP) \
		-p $(SERVING_PORT):80 \
		ghcr.io/nenorrell/qr-ip:latest $(TARGET_PORT)