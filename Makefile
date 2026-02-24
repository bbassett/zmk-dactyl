DOCKER_IMAGE  := zmk-dactyl
BUILD_VOLUME  := zmk-dactyl-build
BOARD         := nice_nano
SHIELDS       := dactyl_manuform_left dactyl_manuform_right
OUTPUT_DIR    := output
WORKSPACE     := /workspace
FLASH_VOLUME  := /Volumes/NICENANO

DOCKER_RUN := docker run --rm \
	-v $(shell pwd):$(WORKSPACE)/config:ro \
	-v $(shell pwd)/$(OUTPUT_DIR):$(WORKSPACE)/$(OUTPUT_DIR) \
	-v $(BUILD_VOLUME):$(WORKSPACE)/build \
	-w $(WORKSPACE) \
	$(DOCKER_IMAGE)

.PHONY: build flash update clean nuke

build:
	@docker image inspect $(DOCKER_IMAGE) >/dev/null 2>&1 || \
		(echo "Docker image not found. Run 'make update' first." && exit 1)
	@mkdir -p $(OUTPUT_DIR)
	@for shield in $(SHIELDS); do \
		echo "Building $$shield..."; \
		$(DOCKER_RUN) sh -c ' \
			west build -s zmk/app -b $(BOARD) -d build/'"$$shield"' --pristine auto \
				-- -DSHIELD='"$$shield"' -DZMK_EXTRA_MODULES=$(WORKSPACE)/config && \
			cp build/'"$$shield"'/zephyr/zmk.uf2 $(OUTPUT_DIR)/'"$$shield"'-$(BOARD).uf2' && \
		echo "  -> $(OUTPUT_DIR)/$$shield-$(BOARD).uf2"; \
	done

flash:
ifeq ($(SIDE),l)
	$(eval UF2 := $(OUTPUT_DIR)/dactyl_manuform_left-$(BOARD).uf2)
else ifeq ($(SIDE),r)
	$(eval UF2 := $(OUTPUT_DIR)/dactyl_manuform_right-$(BOARD).uf2)
else
	$(error Usage: make flash SIDE=l  or  make flash SIDE=r)
endif
	@test -f $(UF2) || (echo "Firmware not found: $(UF2). Run 'make build' first." && exit 1)
	@echo "Waiting for bootloader volume at $(FLASH_VOLUME)..."
	@while [ ! -d $(FLASH_VOLUME) ]; do sleep 0.5; done
	@echo "Flashing $(UF2)..."
	@cp $(UF2) $(FLASH_VOLUME)/
	@echo "Done. Board will reboot automatically."

update:
	docker build --pull --no-cache -t $(DOCKER_IMAGE) .
	-docker volume rm $(BUILD_VOLUME) 2>/dev/null

clean:
	-docker volume rm $(BUILD_VOLUME) 2>/dev/null
	rm -f $(OUTPUT_DIR)/*.uf2

nuke: clean
	-docker rmi $(DOCKER_IMAGE) 2>/dev/null
