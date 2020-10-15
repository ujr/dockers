IMAGE = fossil

all: build

build:
	docker build -t $(IMAGE) .
	#docker build -t $(IMAGE) --no-cache .

shell:
	docker run -it --rm -p 8080:80 -p 8443:443 \
	  --mount "type=bind,source=$$(pwd)/test/fossil,target=/fossil" \
	  $(IMAGE) shell

run:
	docker run --rm -p 8080:80 -p 8443:443 \
	  --mount "type=bind,source=$$(pwd)/test/fossil,target=/fossil" \
	  $(IMAGE) run
