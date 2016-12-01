#!/usr/bin/env bash

cd docker-hyperledger
. setenv.sh
docker-compose -f single-peer-ca.ymal up -d

cd ../docker-webservice
docker build -t ccpx/ws .
docker run -p 9999:8080 -d ccpx/ws
