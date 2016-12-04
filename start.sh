#!/usr/bin/env bash

cd docker-hyperledger
. setenv.sh
docker-compose -f single-peer-ca.yaml up -d

cd ../docker-webservice
docker build -t ccpx/ws .

docker network connect bridge dockerhyperledger_vp_1

docker run --name ccpx_node --net=bridge -p 9999:8080 -d ccpx/ws
