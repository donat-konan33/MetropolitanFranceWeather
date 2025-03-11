.PHONY: local-auth namespace streamlit-secret streamlit-apply airbyte-namespace airbyte-secrets airbyte-install

local-auth:
	kubectl create secret docker-registry gcr-json-key \
  --docker-server=$(LOCATION)-docker.pkg.dev \
  --docker-username=_json_key \
  --docker-password="$(SERVICE_ACCOUNT)" \
  --docker-email=$(EMAIL)

streamlit-namespace:
	kubectl config set-context --current --namespace=$(NAMESPACE)
	kubectl create namespace $(NAMESPACE)

streamlit-secret:
	kubectl create secret generic streamlit-secrets \
		--namespace=$(NAMESPACE) \
  	--from-file=secrets.toml=./.streamlit/secrets.toml \
		--from-literal=DEEPSEEK_API_KEY=$(DEEPSEEK_API_KEY) \
		--from-literal=HUGGINGFACE_API_KEY=$(HUGGINGFACE_API_KEY) \
		--from-literal=OPENAI_API_KEY=$(OPENAI_API_KEY) \
		--from-literal=PANDABI_API_KEY=$(PANDABI_API_KEY)

streamlit-config:
	kubectl create configmap streamlit-config \
  	--from-literal=PROJECT_ID=$(PROJECT_ID)

streamlit-apply:
	kubectl apply -f streamlit-deployment.yaml -n $(NAMESPACE)
	kubectl apply -f streamlit-service.yaml -n $(NAMESPACE)

airbyte-namespace:
	kubectl create namespace airbyte

airbyte-secrets:
	kubectl create secret generic airbyte-config-secrets \
	--namespace=airbyte \
  --from-literal=instance-admin-email=$(AIRBYTE_ADMIN_EMAIL) \
  --from-literal=instance-admin-password=$(AIRBYTE_ADMIN_PASSWORD)

airbyte-install:
	helm repo add airbyte https://airbytehq.github.io/helm-charts
	helm repo update
	helm install \
		airbyte \
		airbyte/airbyte \
		--namespace airbyte \
		--values ./values.yaml

	export POD_NAME=$(kubectl get pods --namespace airbyte -l "app.kubernetes.io/name=webapp" -o jsonpath="{.items[0].metadata.name}")
  	export CONTAINER_PORT=$(kubectl get pod --namespace airbyte $POD_NAME -o jsonpath="{.spec.containers[0].ports[0].containerPort}")
  	echo "Visit http://127.0.0.1:8001 to use your application"
  	kubectl --namespace airbyte port-forward $(POD_NAME) 8001:$(CONTAINER_PORT)
