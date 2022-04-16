# tox-docker

Docker container for running tox against multiple environments. Uses `pyenv` to install and configure a set of python interpreters.

By default the following versions are provided:

* `py36`: via `3.6.15`
* `py37`: via `3.7.13`
* `py38`: via `3.8.13`
* `py39`: via `3.9.11`
* `py310`: via `3.10.3`

These can be overwritten in the `Dockerfile`.

## Usage

Simply copy your app across into the container and run `tox`.

```zsh
docker run -t -v $(pwd):/app saracen9/tox-docker sh -c 'cd /app && tox'
```

An example `.tox.ini` is contained below for illustration purposes. If copying the command above include it in the root of your `/app` and tox will execute using it as a configuration.

```ini
[tox]
isolated_build = true
envlist = py36,py37,py38,py39,py310

[testenv]
deps = pytest
commands = pytest
```
