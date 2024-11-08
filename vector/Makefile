NAMESPACE ?= vector

template:
	$(HELM) template vector vector/vector -f ./values.yaml -f ./customConfig.yaml

apply:
	echo "Using HELM: $(HELM)"
# 	$(KUBECTL) apply -f ./vector.yaml -f ./customConfig.yaml -n $(NAMESPACE)


install:
	$(HELM) upgrade --install vector vector/vector \
	  --namespace $(NAMESPACE) \
	  --create-namespace \
	  --values values.yaml  --values customConfig.yaml

repo:	
	$(HELM) repo add vector https://helm.vector.dev
	$(HELM) repo update