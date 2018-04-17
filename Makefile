default: docker_build

DOCKER_IMAGE ?= v20100/k8s-kubectl
GIT_BRANCH ?= `git rev-parse --abbrev-ref HEAD`

ifeq ($(GIT_BRANCH), master)
	DOCKER_TAG = latest
else
	DOCKER_TAG = $(GIT_BRANCH)
endif

docker_build:
	@docker build \
	  --build-arg VCS_REF=`git rev-parse --short HEAD` \
	  --build-arg BUILD_DATE=`date -u +"%Y-%m-%dT%H:%M:%SZ"` \
	  -t $(DOCKER_IMAGE):$(DOCKER_TAG) .

docker_push:
	# Push to DockerHub
	docker push $(DOCKER_IMAGE):$(DOCKER_TAG)

test:
	docker run $(DOCKER_IMAGE):$(DOCKER_TAG) version --client

test_k8s:
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
        image: v20100/k8s-kubectl\n\
        command: ["kubectl","get", "pods"]\n\
      restartPolicy: Never\n\
' | kubectl create -f -
