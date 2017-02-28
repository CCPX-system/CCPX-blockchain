#!/usr/bin/env bash

ccpx_path="$PWD"

. zSystemLeanDockerBuild.sh

cd "$ccpx_path"

docker stop $(docker ps -a -q)
docker rm -f $(docker ps -a -q)
docker rmi -f $(docker images -q)

cd docker-hyperledger
. setenv.sh
docker-compose -f single-peer-ca.yaml up -d

cd ../docker-webservice
docker build -t ccpx/ws .

docker network connect bridge dockerhyperledger_vp_1

docker run --name ccpx_node --net=bridge -p 9999:8088 ccpx/ws
#docker run --name ccpx_node --net=bridge -d -p 9999:8088 ccpx/ws
