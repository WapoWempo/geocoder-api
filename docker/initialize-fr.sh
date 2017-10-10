#!/bin/bash

PROJECT=$1

die() {
    echo $*
    exit 1
}

set -e

[[ -z "${PROJECT}" ]] && die "You must pass a project name in parameter. For example: $0 geocoder"

docker-compose -p ${PROJECT} rm -sf redis-server-fr
docker volume rm ${PROJECT}_data-fr
docker-compose -p ${PROJECT} up -d redis-server-fr

wget https://bano.openstreetmap.fr/BAN_odbl/BAN_odbl.json.bz2 -O data-fr/BAN_odbl.json.bz2
docker-compose -p ${PROJECT} run --volume $PWD/data-fr:/data --volume $PWD/addok-fr.conf:/etc/addok/addok.conf --entrypoint /bin/bash addok-fr -c "bzcat data/BAN_odbl.json.bz2 | jq -c 'del(.housenumbers[]?.id)' | addok batch"

docker-compose -p ${PROJECT} run --volume $PWD/data-fr:/data --volume $PWD/addok-fr.conf:/etc/addok/addok.conf --entrypoint /bin/bash addok-fr -c "ls data/*.json | xargs cat | addok batch"

docker-compose -p ${PROJECT} exec addok-fr addok ngrams

docker-compose -p ${PROJECT} exec redis-server-fr redis-cli BGSAVE