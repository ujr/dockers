IMAGE = dirvish

all: build

build:
	docker build -t $(IMAGE) .

rebuild:
	docker build -t $(IMAGE) --no-cache .

push:
	docker push ujr246/dirvish:latest

setup init runall shell:
	docker run -it --rm \
	  --mount "type=bind,source=$$(pwd)/test/mirror,target=/mirror" \
	  --mount "type=bind,source=$$(pwd)/test/backup,target=/backup" \
	  $(IMAGE) $@

.PHONY: all build rebuild push setup init runall shell
