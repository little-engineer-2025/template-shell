.PHONY: all
all: deps format lint test

.PHONY: format
format:
	shfmt -i 4 -ci -kp -w  $(shell shfmt -f .)

.PHONY: lint
lint:
	shellcheck $(shell find . -iname '*.sh')

.PHONY: test
test:
	bats -r tests

.PHONY: deps
deps: tools/registry.sh dependencies.sh
	./tools/registry.sh install

.PHONY: release
release:
	./tools/release.sh

