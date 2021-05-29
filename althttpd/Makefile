IMAGE = althttpd

all: build

build:
	docker build -t $(IMAGE) .

rebuild:
	docker build -t $(IMAGE) --no-cache .

push:
	docker push ujr246/$(IMAGE):latest

shell:
	docker run -it --rm -p 443:443 -p 8080:80 \
	  --volume="/etc/group:/etc/group:ro" \
	  --volume="/etc/passwd:/etc/passwd:ro" \
	  --volume="/etc/shadow:/etc/shadow:ro" \
	  --volume="$$(pwd)/www:/www:rw" \
	  $(IMAGE) /bin/sh

run start help:
	docker run -it --rm -p 443:443 -p 8080:80 \
	  --volume="/etc/group:/etc/group:ro" \
	  --volume="/etc/passwd:/etc/passwd:ro" \
	  --volume="/etc/shadow:/etc/shadow:ro" \
	  --volume="$$(pwd)/www:/www:rw" \
	  $(IMAGE) /xilab/entry.sh $@

.PHONY: all build rebuild push run start shell help
