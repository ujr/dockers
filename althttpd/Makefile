IMAGE = althttpd
CONTAINER = althttpd

all: build

build:
	docker build -t $(IMAGE) .

rebuild:
	docker build -t $(IMAGE) --no-cache .

push:
	docker push ujr246/$(IMAGE):latest

setup run shell help:
	docker run -it --rm --name $(CONTAINER) \
	  --publish=443:443 --publish=8080:80 \
	  --volume="/etc/group:/etc/group:ro" \
	  --volume="/etc/passwd:/etc/passwd:ro" \
	  --volume="/etc/shadow:/etc/shadow:ro" \
	  --volume="$$(pwd)/www:/home/www:rw" \
	  $(IMAGE) $@

start:
	docker run --rm --detach --name $(CONTAINER) \
	  --publish=443:443 --publish=8080:80 \
	  --volume="/etc/group:/etc/group:ro" \
	  --volume="/etc/passwd:/etc/passwd:ro" \
	  --volume="/etc/shadow:/etc/shadow:ro" \
	  --volume="$$(pwd)/www:/home/www:rw" \
	  $(IMAGE)

stop:
	docker stop $(CONTAINER)

.PHONY: all build rebuild push setup run shell help start stop
