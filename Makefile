init:
	poetry install

docker-build:
	REPOSITORY=saracen9/tox-docker DOCKER_BUILD=true ./multi-arch.sh Dockerfile

docker-push:
	REPOSITORY=saracen9/tox-docker DOCKER_BUILD=false DOCKER_PUSH=true ./multi-arch.sh