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
	bats test

.PHONY: deps
deps: tools/registry.sh dependencies.sh
	./tools/registry.sh install
