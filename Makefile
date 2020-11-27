BUILD_DIR := build

SOUPAULT := soupault

.PHONY: site
site:
	$(SOUPAULT)

.PHONY: assets
assets:
	cp -r assets/* $(BUILD_DIR)/

.PHONY: all
all: site assets

.PHONY: clean
clean:
	rm -rf $(BUILD_DIR)/*

.PHONY: serve
serve:
	python3 -m http.server --directory $(BUILD_DIR)

.PHONY: deploy
deploy:
	neocities push build/
