IMAGE = dirvish

all: build

build:
	docker build -t $(IMAGE) .
	#docker build -t $(IMAGE) --no-cache .

shell:
	docker run -it --rm \
	  --mount "type=bind,source=$$(pwd)/test/mirror,target=/mirror" \
	  --mount "type=bind,source=$$(pwd)/test/backup,target=/backup" \
	  $(IMAGE) shell

runall:
	docker run --rm \
	  --mount "type=bind,source=$$(pwd)/test/mirror,target=/mirror" \
	  --mount "type=bind,source=$$(pwd)/test/backup,target=/backup" \
	  $(IMAGE) runall
