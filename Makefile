CHART_DIR := charts/bmlt-server
REPO_URL := $(or $(REPO_URL), https://charts.bmlt.app)
CHART_NAME := $(shell awk '/^name:/ {print $$2; exit}' $(CHART_DIR)/Chart.yaml)
CHART_VERSION := $(shell awk '/^version:/ {print $$2; exit}' $(CHART_DIR)/Chart.yaml)
PACKAGE := $(CHART_NAME)-$(CHART_VERSION).tgz
CHART_SOURCES := $(shell find $(CHART_DIR) -type f)

help:  ## Print the help documentation
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

.PHONY: lint
lint:  ## Lint the chart
	helm lint $(CHART_DIR)

.PHONY: template
template:  ## Render the chart with default values
	helm template $(CHART_NAME) $(CHART_DIR)

$(PACKAGE): $(CHART_SOURCES)
	helm lint $(CHART_DIR)
	helm package $(CHART_DIR) --destination .

.PHONY: package
package: $(PACKAGE)  ## Package the chart into a .tgz at the repo root

.PHONY: index
index: $(PACKAGE)  ## Regenerate index.yaml from the packaged charts
	helm repo index . --url $(REPO_URL)

.PHONY: release
release: index  ## Lint, package, and regenerate the repo index
	@echo "Built $(PACKAGE) and updated index.yaml — commit and push to publish."

.PHONY: clean
clean:  ## Remove the .tgz for the current chart version
	rm -f $(PACKAGE)
