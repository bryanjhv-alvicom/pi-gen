#!/bin/bash

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
cd "$(dirname "${DIR}")"

docker build -t pi-gen "${DIR}"

BUILD_OPTS="$*"
time docker run \
	--platform linux/arm/v7 \
	--privileged --cap-add=ALL \
	-v "${PWD}":/pi-gen -w /pi-gen \
	-v /dev:/dev -v /lib/modules:/lib/modules \
	pi-gen \
	bash -e -o pipefail -c "./build.sh ${BUILD_OPTS} &&
	rsync -av work/*/build.log deploy/" &
wait "$!"

ls -lah deploy
