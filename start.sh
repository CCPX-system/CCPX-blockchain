#!/usr/bin/env bash

ccpx_path="$PWD"

# Determine flavor of Linux OS
get_linux_flavor() {
  OS_FLAVOR=`cat /etc/os-release | grep ^NAME | sed -r 's/.*"(.*)"/\1/'`

  if grep -iq 'red' <<< $OS_FLAVOR; then
    OS_FLAVOR="rhel"
  elif grep -iq 'sles' <<< $OS_FLAVOR; then
    OS_FLAVOR="sles"
  elif grep -iq 'ubuntu' <<< $OS_FLAVOR; then
    OS_FLAVOR="ubuntu"
  else
    echo -e "\nERROR: Unsupported Linux Operating System.\n"
    exit 1
  fi
}
# Build and install the Docker Daemon
install_docker() {
  echo -e "\n*** install_docker ***\n"

  # Setup Docker for RHEL or SLES
  if [ $1 == "rhel" ]; then
    DOCKER_URL="ftp://ftp.unicamp.br/pub/linuxpatch/s390x/redhat/rhel7.2/docker-1.11.2-rhel7.2-20160623.tar.gz"
    DOCKER_DIR="docker-1.11.2-rhel7.2-20160623"

    # Install Docker
    cd /tmp
    wget -q $DOCKER_URL
    if [ $? != 0 ]; then
      echo -e "\nERROR: Unable to download the Docker binary tarball.\n"
      exit 1
    fi
    tar -xzf $DOCKER_DIR.tar.gz
    if [ -f /usr/bin/docker ]; then
      mv /usr/bin/docker /usr/bin/docker.orig
    fi
    cp $DOCKER_DIR/docker* /usr/bin

    # Setup Docker Daemon service
    if [ ! -d /etc/docker ]; then
      mkdir -p /etc/docker
    fi

    # Create environment file for the Docker service
    touch /etc/docker/docker.conf
    chmod 664 /etc/docker/docker.conf
    echo 'DOCKER_OPTS="-H tcp://0.0.0.0:2375 -H unix:///var/run/docker.sock -s overlay"' >> /etc/docker/docker.conf
    touch /etc/systemd/system/docker.service
    chmod 664 /etc/systemd/system/docker.service

    # Create Docker service file
    cat > /etc/systemd/system/docker.service <<EOF
[Unit]
Description=Docker Application Container Engine
Documentation=https://docs.docker.com
[Service]
Type=notify
ExecStart=/usr/bin/docker daemon \$DOCKER_OPTS
EnvironmentFile=-/etc/docker/docker.conf
[Install]
WantedBy=default.target
EOF
    # Start Docker Daemon
    systemctl daemon-reload
    systemctl enable docker.service
    systemctl start docker.service
  elif [ $1 == "sles" ]; then
    zypper --non-interactive in docker
    systemctl stop docker.service
    sed -i '/^DOCKER_OPTS/ s/\"$/ \-H tcp\:\/\/0\.0\.0\.0\:2375\"/' /etc/sysconfig/docker
    systemctl enable docker.service
    systemctl start docker.service
  else      # Setup Docker for Ubuntu
    apt-get -y install docker.io
    systemctl stop docker.service
    sed -i "\$aDOCKER_OPTS=\"-H tcp://0.0.0.0:2375 -H unix:///var/run/docker.sock\"" /etc/default/docker
    systemctl enable docker.service
    systemctl start docker.service
  fi

  cd /tmp
  curl -s "https://bootstrap.pypa.io/get-pip.py" -o "get-pip.py"
  python get-pip.py > /dev/null 2>&1
  
  pip install docker-compose
  
  echo -e "*** DONE ***\n"
}


if ! docker images > /dev/null 2>&1; then
  install_docker $OS_FLAVOR
  # Cleanup files and Docker images and containers
  rm -rf /tmp/*

  echo -e "Cleanup Docker artifacts\n"
    # Delete any temporary Docker containers created during the build process
    if [[ ! -z $(docker ps -aq) ]]; then
        docker rm -f $(docker ps -aq)
    fi

  echo -e "\n\nDocker and its supporting components have been successfully installed.\n"
fi

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
