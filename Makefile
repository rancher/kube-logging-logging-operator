DEFAULT_PLATFORMS := linux/amd64,linux/arm64
TARGET_PLATFORMS ?= $(DEFAULT_PLATFORMS)

REPO ?= rancher
IMAGE ?= kube-logging-logging-operator
IMAGE_NAME = $(REPO)/$(IMAGE)
FULL_IMAGE_TAG = $(IMAGE_NAME):$(TAG)
BUILD_ACTION = --load

RUNNER := docker
IMAGE_BUILDER := $(RUNNER) buildx
MACHINE ?= rancher

.DEFAULT_GOAL := ci

.PHONY: all
all: ci

.PHONY: test
test:
	go test -v ./pkg/...

.PHONY: build
build:
	CGO_ENABLED=0 go build -v -o bin/manager ./main.go

.PHONY: ci
ci: test build

.PHONY: buildx-machine
buildx-machine:
	@docker buildx ls | grep $(MACHINE) || \
		docker buildx create --name=$(MACHINE) --platform=$(DEFAULT_PLATFORMS)

.PHONY: build-image
build-image: buildx-machine
	$(IMAGE_BUILDER) build -f Dockerfile \
		--builder $(MACHINE) $(IMAGE_ARGS) \
		--build-arg VERSION=$(VERSION) --platform=$(TARGET_PLATFORMS) -t "$(FULL_IMAGE_TAG)" $(BUILD_ACTION) .
	@echo "Built $(FULL_IMAGE_TAG)"

.PHONY: push-image
push-image: buildx-machine
	$(IMAGE_BUILDER) build -f Dockerfile \
		--builder $(MACHINE) $(IMAGE_ARGS) $(IID_FILE_FLAG) $(BUILDX_ARGS) \
		--build-arg VERSION=$(VERSION) --platform=$(TARGET_PLATFORMS) -t "$(FULL_IMAGE_TAG)" --push .
	@echo "Pushed $(FULL_IMAGE_TAG)"
