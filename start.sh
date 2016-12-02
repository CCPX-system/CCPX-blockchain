#!/usr/bin/env bash

cd docker-hyperledger
. setenv.sh
docker-compose -f single-peer-ca.yaml up -d

cd ../docker-webservice
docker build -t ccpx/ws .
docker run --net=bridge -p 9999:8080 -d ccpx/ws
