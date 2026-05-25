CHART_DIR := charts/bmlt-server
SITE_DIR := site
REPO_URL := $(or $(REPO_URL), https://charts.bmlt.app)
CHART_NAME := $(shell awk '/^name:/ {print $$2; exit}' $(CHART_DIR)/Chart.yaml)
CHART_VERSION := $(shell awk '/^version:/ {print $$2; exit}' $(CHART_DIR)/Chart.yaml)
PACKAGE := $(SITE_DIR)/$(CHART_NAME)-$(CHART_VERSION).tgz
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
	helm package $(CHART_DIR) --destination $(SITE_DIR)

.PHONY: package
package: $(PACKAGE)  ## Package the chart into a .tgz under site/

.PHONY: index
index: $(PACKAGE)  ## Regenerate site/index.yaml from the packaged charts
	helm repo index $(SITE_DIR) --url $(REPO_URL)

.PHONY: release
release: index  ## Lint, package, and regenerate the repo index
	@echo "Built $(PACKAGE) and updated index.yaml — commit and push to publish."

.PHONY: clean
clean:  ## Remove the .tgz for the current chart version
	rm -f $(PACKAGE)

.PHONY: cluster-up
cluster-up:  ## Create a local k3d cluster, deploy MariaDB, and install the chart
	./test/up.sh

.PHONY: cluster-test
cluster-test:  ## Smoke-test the app running in the local cluster
	./test/smoke-test.sh

.PHONY: cluster-down
cluster-down:  ## Delete the local k3d test cluster
	./test/down.sh

.PHONY: e2e
e2e: cluster-up cluster-test  ## Stand up the cluster and run the smoke test
