VERSION := $(shell uv version --short)

SETUP_FILE := .setup-$(VERSION)

all: $(SETUP_FILE)

$(SETUP_FILE):
	uv sync
	uv run scripts/gen_protos.py
	touch $@

.PHONY: clean
clean:
	rm -rf .setup-*
