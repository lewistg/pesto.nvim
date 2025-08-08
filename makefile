.PHONY: format
format:
	stylua lua/ test/spec/ plugin/

.PHONY: test
test:
	busted

.PHONY: test/unit
test/unit:
	busted --run=unit

.PHONY: test/functional
test/functional:
	busted --run=functional
