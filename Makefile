GIT_HASH=$(shell git rev-parse --short HEAD)
QP_IP_IMAGE=ghcr.io/nenorrell/qp-ip
TAG=latest
# X11 socket for GUI forwarding
X11_SOCKET := /tmp/.X11-unix
PORT ?= 80

.PHONY: all build run

build:
	docker build -t $(QP_IP_IMAGE):$(GIT_HASH)

push-qp-ip:
	docker push $(QP_IP_IMAGE):latest

tag-qp-ip: build-qp-ip
	docker tag $(QP_IP_IMAGE):$(GIT_HASH) $(QP_IP_IMAGE):latest

deploy-qp-ip: tag-qp-ip push-qp-ip

run:
	docker run --rm -it \
	  -e DISPLAY=$(DISPLAY) \
	  -v $(X11_SOCKET):$(X11_SOCKET) \
	  --name qr-ip \
	  $(QP_IP_IMAGE) --port $(PORT)