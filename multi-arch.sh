#!/usr/bin/env bash
### SYSTEM PREP:
# docker run --rm --privileged multiarch/qemu-user-static:register
# docker run --privileged --rm tonistiigi/binfmt --install all
#
# NB: on MacOS you will need to `brew install coreutils` for realpath
### USAGE:
# bash REPOSITORY=username/imagename multiarch.sh /path/to/Dockerfile
# eg. bash REPOSITORY=saracen9/tox-docker /Users/admin/repos/tox-docker/Dockerfile
###
DOCKERFILE=$(realpath ${1})
ROOT_DIR=$(dirname ${DOCKERFILE})
IMAGES=""
CACHE=${CACHE}  # can pass in `--no-cache`
# BUILD/PUSH
BUILD=${DOCKER_BUILD:-true}
PUSH=${DOCKER_PUSH:-false}
# SENSE CHECKING
if [ -z ${REPOSITORY} ]; then echo 'Please set REPOSITORY as an environment variable'; exit; fi
if [ -z ${DOCKERFILE} ] && [ ${BUILD} == true ]; then echo 'BUILD selected but no Dockerfile set'; exit; fi


cd ${ROOT_DIR}

if [ ${BUILD} == true ]
then
    docker buildx build ${CACHE} -t ${REPOSITORY} .
    for arch in amd64 arm64 386 armv6 armv7; do
        case ${arch} in
            amd64   ) platform="linux/amd64" ;;
            arm64   ) platform="linux/arm64" ;;
            riscv64 ) platform="linux/riscv64" ;;
            386     ) platform="linux/386" ;;
            armv7   ) platform="linux/arm/v7" ;;
            armv6   ) platform="linux/arm/v6" ;;
        esac
        echo -e "=== Building ${arch} | ${platform} ==="
        docker buildx build ${CACHE} --platform ${platform} -t ${REPOSITORY}:${arch} .
        IMAGES=${IMAGES}" ${REPOSITORY}:${arch}"
        if [ ${PUSH} == true ]
        then
            docker push ${REPOSITORY}:${arch}
        fi
    done
fi

if [ ${BUILD} == true ]
then
    echo ${IMAGES}
    docker manifest rm ${REPOSITORY} || true
    docker manifest create ${REPOSITORY} ${REPOSITORY}:latest
    docker manifest create ${REPOSITORY} ${REPOSITORY}:latest --amend ${IMAGES}
fi
if [ ${PUSH} == true ]
then
    docker manifest rm ${REPOSITORY} || true
    docker manifest create ${REPOSITORY} ${REPOSITORY}:latest
    for i in $(docker images '${REPOSITORY}' --format '{{.Repository}}:{{.Tag}}'); 
    do 
        echo "=== Pushing {i} ==="
        docker push ${i} && \
        docker manifest create ${REPOSITORY} ${REPOSITORY}:latest --amend ${i} || true;
    done
    docker manifest push ${REPOSITORY}
fi