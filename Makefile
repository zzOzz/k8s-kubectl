default: docker_build

DOCKER_IMAGE = v20100/k8s-kubectl
GIT_BRANCH = $$(git rev-parse --abbrev-ref HEAD)
DOCKER_TAG = $(GIT_BRANCH)

docker_build:
	@if [ $(DOCKER_TAG) = "master" ]; then\
		docker build --no-cache --build-arg VCS_REF=`git rev-parse --short HEAD` --build-arg BUILD_DATE=`date -u +"%Y-%m-%dT%H:%M:%SZ"` -t $(DOCKER_IMAGE):latest . ;\
	else \
		docker build --no-cache --build-arg VCS_REF=`git rev-parse --short HEAD` --build-arg BUILD_DATE=`date -u +"%Y-%m-%dT%H:%M:%SZ"` -t $(DOCKER_IMAGE):$(DOCKER_TAG) . ;\
	fi
docker_push:
	# Push to DockerHub
	@if [ $(DOCKER_TAG) = "master" ]; then\
		docker push $(DOCKER_IMAGE):latest;\
	else\
		docker push $(DOCKER_IMAGE):$(DOCKER_TAG);\
	fi\

test:
	docker run $(DOCKER_IMAGE):$(DOCKER_TAG) version --client

test_k8s:
	@kubectl delete job kubectl-test --namespace gitlab
	@printf 'apiVersion: batch/v1\n\
kind: Job\n\
metadata:\n\
  name: kubectl-test\n\
  namespace: gitlab\n\
spec:\n\
  template:\n\
    spec:\n\
      containers:\n\
      - name: k8s-kubectl\n\
        image: v20100/k8s-kubectl:master\n\
        imagePullPolicy: Always\n\
        command: ["kubectl","get", "pods"]\n\
      restartPolicy: Never\n\
' | kubectl create -f -
