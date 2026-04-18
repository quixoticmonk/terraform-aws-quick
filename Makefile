.PHONY: all fmt validate test docs clean

all: fmt validate test docs

clean:
	./scripts/clean.sh

fmt:
	terraform fmt -recursive

validate:
	terraform init -backend=false
	terraform validate

test:
	terraform test

docs:
	terraform-docs .
