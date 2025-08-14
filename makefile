SHELL := /usr/bin/env bash
ANSIBLE_IMAGE := registry.gitlab.com/<group>/<proj>/ansible-runner:1.0.0
INVENTORY ?= ansible/inventories/lab/hosts.ini
EXTRA ?=

.PHONY: init lint lock build run verify teardown molecule

init:
	pre-commit install -t pre-commit -t commit-msg

lint:
	pre-commit run --all-files

lock:
	ansible-galaxy collection install -r ansible/collections/requirements.yml --force

build:
	docker build -f .gitlab/ci/images/ansible-runner.Dockerfile -t $(ANSIBLE_IMAGE) .

run:
	docker run --rm -v $$(pwd):/work -w /work -v $$HOME/.ssh:/root/.ssh:ro \
	$(ANSIBLE_IMAGE) \
	ansible-playbook -i $(INVENTORY) ansible/playbooks/apply.yml $(EXTRA)

verify:
	docker run --rm -v $$(pwd):/work -w /work -v $$HOME/.ssh:/root/.ssh:ro \
	$(ANSIBLE_IMAGE) \
	ansible-playbook -i $(INVENTORY) ansible/playbooks/verify.yml $(EXTRA)

teardown:
	docker run --rm -v $$(pwd):/work -w /work -v $$HOME/.ssh:/root/.ssh:ro \
	$(ANSIBLE_IMAGE) \
	ansible-playbook -i $(INVENTORY) ansible/playbooks/rollback.yml $(EXTRA)

molecule:
	docker run --rm -v $$(pwd):/work -w /work $(ANSIBLE_IMAGE) \
	molecule test -s $(SCENARIO)
