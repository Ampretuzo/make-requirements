.DELETE_ON_ERROR:
SHELL := /bin/bash

WITH_VENV := source venv/bin/activate && 

.PHONY: clean
clean:
	rm -f .make.*
	rm -rf venv*

# Environment:

venv/bin/activate:
	/usr/bin/python3.8 --version
	virtualenv --python=/usr/bin/python3.8 venv

.make.venv: venv/bin/activate
	touch .make.venv

.make.venv.pip-tools: .make.venv requirements/pip-tools.txt
	${WITH_VENV} pip install -r requirements/pip-tools.txt
	touch .make.venv.pip-tools

.make.venv.dev: .make.venv.pip-tools
.make.venv.dev: requirements/pip-tools.txt requirements/base.txt requirements/dev.txt
	@ echo 'NOTE: `touch requirements/{base,deploy,dev}.txt` to snooze dependency upgrade when `.in` files are modified.'
	${WITH_VENV} pip-sync requirements/pip-tools.txt requirements/base.txt requirements/dev.txt
	touch .make.venv.dev

# Requirements:

requirements/base.txt: requirements/pip-tools.txt 
requirements/base.txt: requirements/base.in
requirements/base.txt: | .make.venv.pip-tools
	${WITH_VENV} pip-compile --generate-hashes requirements/base.in

requirements/deploy.txt: requirements/pip-tools.txt requirements/base.txt 
requirements/deploy.txt: requirements/deploy.in
requirements/deploy.txt: | .make.venv.pip-tools
	${WITH_VENV} pip-compile --generate-hashes requirements/deploy.in

requirements/dev.txt: requirements/pip-tools.txt requirements/base.txt requirements/deploy.txt 
requirements/dev.txt: requirements/dev.in
requirements/dev.txt: | .make.venv.pip-tools
	${WITH_VENV} pip-compile --generate-hashes requirements/dev.in
	
.PHONY: requirements
requirements: requirements/base.txt requirements/dev.txt requirements/deploy.txt
	@ echo 'NOTE: `rm requirements/{base,deploy,dev}.txt` before `make requirements` to upgrade all the dependencies.'

# Entrypoints:

.PHONY: bash
bash: .make.venv.dev
	# Starting a new bash session with activated virtual environment.
	@ ${WITH_VENV} bash --rcfile <(cat ~/.bashrc venv/bin/activate)

.PHONY: test
test: .make.venv.dev
	@ ${WITH_VENV} python -c 'import pytest; print("pytest would run as version " + pytest.__version__ + "!")'

