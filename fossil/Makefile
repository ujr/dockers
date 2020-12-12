IMAGE = fossil

all: build

build:
	docker build -t $(IMAGE) .

rebuild:
	docker build -t $(IMAGE) --no-cache .

push:
	docker push ujr246/fossil:latest

start shell help server:
	docker run -it --rm -p 9080:80 -p 9443:443 \
	  --mount "type=bind,source=$$(pwd)/test/fossil,target=/fossil" \
	  $(IMAGE) $@

.PHONY: all build rebuild start shell help
