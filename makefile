.PHONY: format
format:
	stylua lua/ test/spec/ plugin/

.PHONY: type-check
type-check:
	lua-language-server --check lua

.PHONY: test
test:
	busted

.PHONY: test/unit
test/unit:
	busted --run=unit

.PHONY: test/functional
test/functional:
	busted --run=functional
