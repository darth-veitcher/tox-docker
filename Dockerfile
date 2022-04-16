FROM alpine

USER root

ENV PYTHONUNBUFFERED=1

ARG PYTHON_DEFAULT_VERSION
ENV PYTHON_DEFAULT_VERSION=${PYTHON_VERSION:-3.9.11}
ENV PYTHON_STABLE_VERSIONS="3.6.15 3.7.13 3.8.13 3.9.11"
ENV PYTHON_LATEST_VERSION="3.10.3"
ENV PYTHON_ALL_VERSIONS=${PYTHON_STABLE_VERSIONS}' '${PYTHON_LATEST_VERSION}

RUN adduser -u 1000 -G users -h /home/alpine -D alpine
# https://stackoverflow.com/a/43743532/322358
ENV ENV="/home/alpine/.profile"

# pyenv deps
RUN \
    set -x && \
    apk add --no-cache \
        git bash build-base libffi-dev \
        openssl-dev bzip2-dev zlib-dev \
        readline-dev sqlite-dev curl && \
    rm -rf /var/cache/apk/*

USER alpine

RUN \
    cd /home/alpine && \
    git clone https://github.com/pyenv/pyenv.git /home/alpine/.pyenv && \
    cd /home/alpine/.pyenv && \
    src/configure && make -C src && \
    echo 'export PYENV_ROOT="$HOME/.pyenv"' >> /home/alpine/.profile && \
    echo 'export PATH="$PYENV_ROOT/bin:$PATH"' >> /home/alpine/.profile && \
    echo 'eval "$(pyenv init --path)"' >> /home/alpine/.profile && \
    echo 'eval "$(pyenv init -)"' >> /home/alpine/.profile && \
    # PLUGINS
    mkdir -p /home/alpine/.pyenv/plugins && \
    # virtualenv
    git clone https://github.com/pyenv/pyenv-virtualenv.git /home/alpine/.pyenv/plugins/pyenv-virtualenv && \
    echo 'eval "$(pyenv virtualenv-init -)"' >> /home/alpine/.profile && \
    # update
    git clone https://github.com/pyenv/pyenv-update.git /home/alpine/.pyenv/lugins/pyenv-update

# Add stable versions as a single layer so we can cache for build and push speed
RUN source ~/.profile && \
    for v in ${PYTHON_STABLE_VERSIONS}; do pyenv install $v; done && \
    pyenv global ${PYTHON_DEFAULT_VERSION} && \
    pip install --upgrade pip tox && \
    pyenv rehash

# Add latest (constantly changing) versions as a single layer
RUN source ~/.profile && \
    pyenv install ${PYTHON_LATEST_VERSION} && \
    pyenv rehash

USER root

# Create specific aliases
RUN for v in ${PYTHON_ALL_VERSIONS}; \
    do ln -s /home/alpine/.pyenv/versions/${v}/bin/python \
    /usr/local/bin/python$(echo $v | awk -F. '{print $1"."$2}'); done && \
    echo -e 'source /home/alpine/.profile\ntox' > /usr/local/bin/tox && chmod +x /usr/local/bin/tox

USER alpine