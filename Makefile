BUILD_DIR := build

# In practice it's in my ~/.local/bin
SOUPAULT := soupault

.PHONY: site
site:
	$(SOUPAULT)
	scripts/json2feed.py index.json > $(BUILD_DIR)/atom.xml

.PHONY: assets
assets:
	cp -r assets/* $(BUILD_DIR)/

.PHONY: feed
feed: site
	scripts/json2feed.py index.json > $(BUILD_DIR)/atom.xml

.PHONY: all
all: site assets feed

.PHONY: clean
clean:
	rm -rf $(BUILD_DIR)/*

.PHONY: serve
serve:
	python3 -m http.server --directory $(BUILD_DIR)

.PHONY: deploy
deploy:
	neocities push build/
