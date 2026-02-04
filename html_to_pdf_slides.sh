#!/bin/sh

docker run --rm -t -v $(pwd):/slides ghcr.io/astefanutti/decktape \
  reveal \
  --progress \
  docs/post/abaco26/abaco26_slides.html \
  docs/post/abaco26/abaco26_slides.pdf
