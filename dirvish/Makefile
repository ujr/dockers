IMAGE = dirvish

all: build

build:
	docker build -t $(IMAGE) --no-cache .

testrun:
	docker run -it --rm \
	  --mount "type=bind,source=$$(pwd)/test/mirror,target=/mirror" \
	  --mount "type=bind,source=$$(pwd)/test/backup,target=/backup" \
	  $(IMAGE) /bin/sh

