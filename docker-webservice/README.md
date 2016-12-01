# docker-ibc
Dockerfile for hosting Node.js application on s390x server with some express's webservice bootstraper

#build docker image
docker build -t ccpx/ws .

#run image as portforwared container
docker run -p 9999:8080 -d ccpx/ws
