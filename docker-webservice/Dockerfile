#!/bin/sh

FROM s390x/node:6.9.1

# Create app directory
run ["mkdir", "-p", "/usr/src/app"]
WORKDIR /usr/src/app

# Install app dependencies
COPY package.json /usr/src/app/
run npm install

# Bundle app source
COPY . /usr/src/app

EXPOSE 8080
CMD [ "npm", "start" ]
