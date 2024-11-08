# Default to dev environment unless UAT is specified
ENV ?= dev

ifeq ($(ENV),uat)
    export KUBECONFIG=~/.kube/3-infra-dev
else
    export KUBECONFIG=~/.kube/kind
endif

CLICKHOUSE_SERVER_24_3 := clickhouse/clickhouse-server:24.3.13.40
OPERATOR_VERSION := 0.24.0
ALTINITY_OPERATOR := altinity/clickhouse-operator:$(OPERATOR_VERSION)
METRICS_EXPORTER := altinity/metrics-exporter:$(OPERATOR_VERSION)
PROJECT_NAME := alerts-observability
NAMESPACE := alerts-observability

KUBECTL := KUBECONFIG=$(KUBECONFIG) kubectl
HELM := KUBECONFIG=$(KUBECONFIG) helm

include vector/Makefile

.PHONY: dev-up
dev-up:
	kind create cluster -n $(PROJECT_NAME) --kubeconfig $(KUBECONFIG)
	make pull-images
	make load-images
	make install-operator
	make apply-base

.PHONY: dev-down
dev-down:
	kind delete cluster -n $(PROJECT_NAME)  --kubeconfig $(KUBECONFIG)

.PHONY: pull-images
pull-images:
	docker pull $(CLICKHOUSE_SERVER_24_3)
	# docker pull $(CLICKHOUSE_SERVER_23_8)
	docker pull $(ALTINITY_OPERATOR)
	docker pull $(METRICS_EXPORTER)


.PHONY: load-images
load-images: pull-images
	# kind load docker-image $(CLICKHOUSE_SERVER_23_8) -n $(PROJECT_NAME)
	kind load docker-image $(CLICKHOUSE_SERVER_24_3) -n $(PROJECT_NAME)
	kind load docker-image $(ALTINITY_OPERATOR) -n $(PROJECT_NAME)
	kind load docker-image $(METRICS_EXPORTER) -n $(PROJECT_NAME)

.PHONY: install-operator
install-operator:
	curl -s https://raw.githubusercontent.com/Altinity/clickhouse-operator/master/deploy/operator-web-installer/clickhouse-operator-install.sh | KUBECONFIG=$(KUBECONFIG) OPERATOR_VERSION=$(OPERATOR_VERSION) OPERATOR_NAMESPACE=$(NAMESPACE) bash

.PHONY: apply-base
apply-base:
	$(KUBECTL) apply -k base  -n $(NAMESPACE)
	# $(KUBECTL) rollout restart sts/chi-clickhouse-clickhouse-0-0 -n $(NAMESPACE)

.PHONY: install-uat
install-uat: install-operator
	$(KUBECTL) apply -k overlays/uat -n $(NAMESPACE)

.PHONY: uninstall-uat
uninstall-uat:
	$(KUBECTL) delete -k overlays/uat -n $(NAMESPACE)

.PHONY: get-pods
get-pods:
	$(KUBECTL) get pods -n $(NAMESPACE)

.PHONY: logs
logs:
	$(KUBECTL) logs -n $(NAMESPACE) -l clickhouse.altinity.com/chi=clickhouse

.PHONY: uninstall-base
uninstall-base:
	$(KUBECTL) delete -k base

.PHONY: dev-watch
dev-watch:
	$(KUBECTL) get pods -n $(NAMESPACE) -w

.PHONY: uat-watch
uat-watch:
	$(KUBECTL) get pods -n $(NAMESPACE) -w



.PHONY: install-vector
install-vector:
	make -C vector install HELM="$(HELM)"

vector-template:
	make -C vector template HELM="$(HELM)"
