BOARD ?= nice_nano
DOCKER_IMAGE = zmkfirmware/zmk-build-arm:stable
WORKSPACE = $(shell dirname $(PWD))
MODULE_PATH = /workspace/config

.PHONY: init update build clean left right all

# First-time setup: initialize west workspace
init:
	cd $(WORKSPACE) && docker run --rm \
		-v $(PWD):/workspace/config \
		-w /workspace \
		$(DOCKER_IMAGE) \
		sh -c "west init -l config && west update"

# Update ZMK and dependencies
update:
	cd $(WORKSPACE) && docker run --rm \
		-v $(PWD):/workspace/config \
		-v $(WORKSPACE)/zmk:/workspace/zmk \
		-v $(WORKSPACE)/zephyr:/workspace/zephyr \
		-v $(WORKSPACE)/modules:/workspace/modules \
		-w /workspace \
		$(DOCKER_IMAGE) \
		west update

# Build a shield: make build SHIELD=dactyl_manuform_left
build:
	cd $(WORKSPACE) && docker run --rm \
		-v $(PWD):/workspace/config \
		-v $(WORKSPACE)/zmk:/workspace/zmk \
		-v $(WORKSPACE)/zephyr:/workspace/zephyr \
		-v $(WORKSPACE)/modules:/workspace/modules \
		-v $(WORKSPACE)/build:/workspace/build \
		-w /workspace \
		$(DOCKER_IMAGE) \
		west build -s zmk/app -b $(BOARD) -d build -- -DSHIELD=$(SHIELD) -DZMK_EXTRA_MODULES=$(MODULE_PATH)
	cp $(WORKSPACE)/build/zephyr/zmk.uf2 $(SHIELD)-$(BOARD).uf2
	@echo "Firmware written to $(SHIELD)-$(BOARD).uf2"

# Shortcut targets
left:
	$(MAKE) build SHIELD=dactyl_manuform_left

right:
	$(MAKE) build SHIELD=dactyl_manuform_right

all: left right

clean:
	rm -rf $(WORKSPACE)/build *.uf2
