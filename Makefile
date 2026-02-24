DOCKER_IMAGE  := zmk-dactyl
BUILD_VOLUME  := zmk-dactyl-build
BOARD         := nice_nano
SHIELDS       := dactyl_manuform_left dactyl_manuform_right
OUTPUT_DIR    := output
WORKSPACE     := /workspace

DOCKER_RUN := docker run --rm \
	-v $(shell pwd):$(WORKSPACE)/config:ro \
	-v $(shell pwd)/$(OUTPUT_DIR):$(WORKSPACE)/$(OUTPUT_DIR) \
	-v $(BUILD_VOLUME):$(WORKSPACE)/build \
	-w $(WORKSPACE) \
	$(DOCKER_IMAGE)

.PHONY: build update clean nuke

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

update:
	docker build --pull --no-cache -t $(DOCKER_IMAGE) .
	-docker volume rm $(BUILD_VOLUME) 2>/dev/null

clean:
	-docker volume rm $(BUILD_VOLUME) 2>/dev/null
	rm -f $(OUTPUT_DIR)/*.uf2

nuke: clean
	-docker rmi $(DOCKER_IMAGE) 2>/dev/null
