GIT_HASH=$(shell git rev-parse --short HEAD)
QP_IP_IMAGE=ghcr.io/nenorrell/qp-ip
TAG=latest
PORT ?= 80

.PHONY: all build run tag deploy

build:
	docker buildx build -t $(QP_IP_IMAGE):$(GIT_HASH) .

push:
	docker push $(QP_IP_IMAGE):latest

tag: build
	docker tag $(QP_IP_IMAGE):$(GIT_HASH) $(QP_IP_IMAGE):latest

deploy: tag push

run:
	docker run --rm -it -p 8080:80 $(QP_IP_IMAGE):latest --port 8080