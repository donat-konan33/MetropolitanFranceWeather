.PHONY: local-auth namespace streamlit-secret streamlit-apply

local-auth:
	kubectl create secret docker-registry gcr-json-key \
  --docker-server=$(LOCATION)-docker.pkg.dev \
  --docker-username=_json_key \
  --docker-password="$(SERVICE_ACCOUNT)" \
  --docker-email=$(EMAIL)

namespace:
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
