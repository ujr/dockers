IMAGE = althttpd

all: build

build:
	docker build -t $(IMAGE) .

rebuild:
	docker build -t $(IMAGE) --no-cache .

push:
	docker push ujr246/$(IMAGE):latest

setup run start shell help:
	docker run -it --rm -p 443:443 -p 8080:80 \
	  --volume="/etc/group:/etc/group:ro" \
	  --volume="/etc/passwd:/etc/passwd:ro" \
	  --volume="/etc/shadow:/etc/shadow:ro" \
	  --volume="$$(pwd)/www:/home/www:rw" \
	  $(IMAGE) $@

.PHONY: all build rebuild push setup run start shell help
