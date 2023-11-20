.PHONY: format
format:
	swift-format -i -r .
.PHONY: lint
lint:
	swift-format lint -r .
