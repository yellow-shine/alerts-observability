# Define variables for image names and tags
CLICKHOUSE_SERVER_23_8 := clickhouse/clickhouse-server:23.8
CLICKHOUSE_SERVER_24_3 := clickhouse/clickhouse-server:24.3.13.40
OPERATOR_VERSION := 0.24.0
ALTINITY_OPERATOR := altinity/clickhouse-operator:$(OPERATOR_VERSION)
METRICS_EXPORTER := altinity/metrics-exporter:$(OPERATOR_VERSION)
PROJECT_NAME := alerts-analysis


.PHONY: dev-up
dev-up:
	kind create cluster -n $(PROJECT_NAME)
	make load-images
	make install-operator
	make apply-base

.PHONY: dev-down
dev-down:
	kind delete cluster -n $(PROJECT_NAME)

.PHONY: pull-images
pull-images:
	docker pull $(CLICKHOUSE_SERVER_24_3)
	docker pull $(CLICKHOUSE_SERVER_23_8)
	docker pull $(ALTINITY_OPERATOR)
	docker pull $(METRICS_EXPORTER)


.PHONY: load-images
load-images: pull-images
	kind load docker-image $(CLICKHOUSE_SERVER_23_8) -n $(PROJECT_NAME)
	kind load docker-image $(CLICKHOUSE_SERVER_24_3) -n $(PROJECT_NAME)
	kind load docker-image $(ALTINITY_OPERATOR) -n $(PROJECT_NAME)
	kind load docker-image $(METRICS_EXPORTER) -n $(PROJECT_NAME)

.PHONY: install-operator
install-operator:
	curl -s https://raw.githubusercontent.com/Altinity/clickhouse-operator/master/deploy/operator-web-installer/clickhouse-operator-install.sh | OPERATOR_VERSION=$(OPERATOR_VERSION) OPERATOR_NAMESPACE=alerts-analysis bash

.PHONY: apply-base
apply-base:
	kubectl apply -k base

.PHONY: get-pods
get-pods:
	kubectl get pods -n alerts-analysis

.PHONY: logs
logs:
	kubectl logs -n alerts-analysis -l clickhouse.altinity.com/chi=clickhouse

.PHONY: uninstall-base
uninstall-base:
	kubectl delete -k base

.PHONY: dev-watch
dev-watch:
	kubectl get pods -n alerts-analysis -w

.PHONY: install-uat
install-uat:
	kubectl apply -k overlays/uat