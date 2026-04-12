ENV ?= dev

.PHONY: sync diff destroy template show-dag

sync:
	helmfile -e $(ENV) sync

diff:
	helmfile -e $(ENV) diff

destroy:
	helmfile -e $(ENV) destroy

template:
	helmfile -e $(ENV) template

show-dag:
	helmfile -e $(ENV) show-dag
