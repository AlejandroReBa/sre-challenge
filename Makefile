SHELL=/bin/bash

# Usage:
# make help                     # print all available targets from this Makefile
# make ci-check                 # runs CI check github action pipeline locally in local
# make ci-build                 # runs CI build github action to build&push the docker image to Dockerhub in local
# make ci-deploy-core-layer		# deploys kubernetes object that are not a first level dependency of our project
# make ci-deploy				# [generic method] deploys the component helm chart to kubernetes cluster
	# make ci-deploy-local		# deploys the component helm chart to local kubernetes cluster
	# make ci-deploy-dev 		# deploys the component helm chart to remote/local kubernetes cluster specified in active kubecontext
	# make ci-deploy-stage 	    # deploys the component helm chart to remote kubernetes cluster specified in active kubecontext - PoC purpose
	# make ci-deploy-prod       # deploys the component helm chart to remote kubernetes cluster specified in active kubecontext - PoC purpose
	# ...

help:
	@grep '^[^#[:space:]].*:' Makefile

ci-check: 
	act -W .github/workflows/ci-check.yaml --container-architecture linux/amd64 -s SNYK_TOKEN

ci-build: 
	act -j build --container-architecture linux/amd64  -s DOCKERHUB_USERNAME -s DOCKERHUB_TOKEN -s GITHUB_TOKEN

ci-deploy-core-layer:
	kubectl apply -f ./ops/core-layer

ci-deploy:
ifndef DEPLOY_K8S_ENV
	$(error DEPLOY_K8S_ENV is undefined)
endif
	helm template ./ops/charts -f ./ops/charts/env/$(DEPLOY_K8S_ENV)/values.yaml --set imageTag=`(git rev-parse HEAD)`

ci-deploy-local:
	$(MAKE) ci-deploy \
	        DEPLOY_K8S_ENV=local

ci-deploy-dev:
	$(MAKE) ci-deploy \
	        DEPLOY_K8S_ENV=dev    

ci-deploy-stage:
	$(MAKE) ci-deploy \
	        DEPLOY_K8S_ENV=stage

ci-deploy-prod:
	$(MAKE) ci-deploy \
	        DEPLOY_K8S_ENV=prod


