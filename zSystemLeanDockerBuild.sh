#!/bin/bash

# Build out the Hyperledger Fabric environment for Linux on z Systems

# Global Variables
OS_FLAVOR=""
GO_VER="1.7.3"

usage() {
  cat << EOF

Usage:  `basename $0` options

This script installs and configures a Hyperledger Fabric environment on a Linux on
IBM z Systems instance.  The execution of this script assumes that you are starting
from a new Linux on z Systems instance.  The script will autodetect the Linux
distribution (currently RHEL, SLES, and Ubuntu) and build out the necessary components.
After running this script, logout and then login to pick up updates to
Hyperledger Fabric specific environment variables.

To run the script:
sudo su -  (if you currently are not root)
<path-of-script>/zSystemsFabricBuild-v1.0.sh

The script will install the following components:
    - Docker and supporting Hyperledger Fabric Docker images
    - Golang
    - IBM Java 1.8
    - Nodejs 6.7.0
    - Hyperledger Fabric core components (fabric, fabric-ca, and fabric-sdk-node)


EOF
  exit 1
}

# Install prerequisite packages for an RHEL Hyperledger build
prereq_rhel() {
  echo -e "\nInstalling RHEL prerequisite packages\n"
  yum -y -q install git gcc gcc-c++ wget tar python-setuptools python-devel device-mapper libtool-ltdl-devel libffi-devel openssl-devel
  if [ $? != 0 ]; then
    echo -e "\nERROR: Unable to install pre-requisite packages.\n"
    exit 1
  fi
  if [ ! -f /usr/bin/s390x-linux-gnu-gcc ]; then
    ln -s /usr/bin/s390x-redhat-linux-gcc /usr/bin/s390x-linux-gnu-gcc
  fi
}

# Install prerequisite packages for an SLES Hyperledger build
prereq_sles() {
  echo -e "\nInstalling SLES prerequisite packages\n"
  zypper --non-interactive in git-core gcc make gcc-c++ patterns-sles-apparmor  python-setuptools python-devel libtool libffi48-devel libopenssl-devel
  if [ $? != 0 ]; then
    echo -e "\nERROR: Unable to install pre-requisite packages.\n"
    exit 1
  fi
  if [ ! -f /usr/bin/s390x-linux-gnu-gcc ]; then
    ln -s /usr/bin/gcc /usr/bin/s390x-linux-gnu-gcc
  fi
}

# Install prerequisite packages for an Unbuntu Hyperledger build
prereq_ubuntu() {
  echo -e "\nInstalling Ubuntu prerequisite packages\n"
  apt-get update
  apt-get -y install build-essential git debootstrap python-setuptools python-dev alien libtool libffi-dev libssl-dev
  if [ $? != 0 ]; then
    echo -e "\nERROR: Unable to install pre-requisite packages.\n"
    exit 1
  fi
}

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

# Install the Golang compiler for the s390x platform
install_golang() {
  echo -e "\n*** install_golang ***\n"
  export GOROOT="/opt/go"
  cd /tmp
  wget --quiet --no-check-certificate https://storage.googleapis.com/golang/go${GO_VER}.linux-s390x.tar.gz
  tar -xvf go${GO_VER}.linux-s390x.tar.gz
  mv go /opt
  chmod 775 /opt/go
  echo -e "*** DONE ***\n"
}

# Build the Hyperledger Fabric peer components
build_hyperledger_fabric() {
  echo -e "\n*** build_hyperledger_fabric ***\n"
  # Setup Environment Variables
  export GOPATH=$HOME/git
  export PATH=$GOROOT/bin:$PATH

  # Download latest Hyperledger Fabric codebase
  if [ ! -d $GOPATH/src/github.com/hyperledger ]; then
    mkdir -p $GOPATH/src/github.com/hyperledger
  fi
  cd $GOPATH/src/github.com/hyperledger
  # Delete fabric directory, if it exists
  rm -rf fabric
  git clone http://gerrit.hyperledger.org/r/fabric

  cd $GOPATH/src/github.com/hyperledger/fabric
  make native docker

  if [ $? != 0 ]; then
    echo -e "\nERROR: Unable to build the Hyperledger Fabric peer components.\n"
    exit 1
  fi

  echo -e "*** DONE ***\n"
}

# Build the Hyperledger Fabric Membership Services components
build_hyperledger_fabric-ca() {
  echo -e "\n*** build_hyperledger_fabric-ca ***\n"

  # Download latest Hyperledger Fabric codebase
  if [ ! -d $GOPATH/src/github.com/hyperledger ]; then
    mkdir -p $GOPATH/src/github.com/hyperledger
  fi
  cd $GOPATH/src/github.com/hyperledger
  # Delete fabric directory, if it exists
  rm -rf fabric-ca
  git clone http://gerrit.hyperledger.org/r/fabric-ca

  cd $GOPATH/src/github.com/hyperledger/fabric-ca
  make fabric-ca fabric-ca-server fabric-ca-client docker

  if [ $? != 0 ]; then
    echo -e "\nERROR: Unable to build the Hyperledger Membership Services components.\n"
    exit 1
  fi

  echo -e "*** DONE ***\n"
}

# Build the Hyperledger Fabric Node SDK components
build_hyperledger_fabric-sdk-node() {
  echo -e "\n*** build_hyperledger_fabric-sdk-node ***\n"

  # Download latest Hyperledger Fabric codebase
  if [ ! -d $GOPATH/src/github.com/hyperledger ]; then
    mkdir -p $GOPATH/src/github.com/hyperledger
  fi
  cd $GOPATH/src/github.com/hyperledger
  # Delete fabric directory, if it exists
  rm -rf fabric-sdk-node
  git clone http://gerrit.hyperledger.org/r/fabric-sdk-node

  cd $GOPATH/src/github.com/hyperledger/fabric-sdk-node
  npm install && npm install -g gulp && npm install -g istanbul && gulp && gulp ca && rm -rf node_modules/fabric-ca-client && npm install

  if [ $? != 0 ]; then
    echo -e "\nERROR: Unable to build the Hyperledger Node SDK components.\n"
    exit 1
  fi

  echo -e "*** DONE ***\n"
}

# Install IBM Java 1.8
install_java() {
  echo -e "\n*** install_java ***\n"
  JAVA_VERSION=1.8.0_sr3fp12
  ESUM_s390x="46766ac01bc2b7d2f3814b6b1561e2d06c7d92862192b313af6e2f77ce86d849"
  ESUM_ppc64le="6fb86f2188562a56d4f5621a272e2cab1ec3d61a13b80dec9dc958e9568d9892"
  eval ESUM=\$ESUM_s390x
  BASE_URL="https://public.dhe.ibm.com/ibmdl/export/pub/systems/cloud/runtimes/java/meta/"
  YML_FILE="sdk/linux/s390x/index.yml"
  wget -q -U UA_IBM_JAVA_Docker -O /tmp/index.yml $BASE_URL/$YML_FILE
  JAVA_URL=$(cat /tmp/index.yml | sed -n '/'$JAVA_VERSION'/{n;p}' | sed -n 's/\s*uri:\s//p' | tr -d '\r')
  wget -q -U UA_IBM_JAVA_Docker -O /tmp/ibm-java.bin $JAVA_URL
  echo "$ESUM  /tmp/ibm-java.bin" | sha256sum -c -
  if [ $? != 0 ]; then
    echo -e "\nERROR: Java image digests do not match.\n Unable to build the Hyperledger Fabric components.\n"
    exit 1
  fi
  echo "INSTALLER_UI=silent" > /tmp/response.properties
  echo "USER_INSTALL_DIR=/opt/ibm/java" >> /tmp/response.properties
  echo "LICENSE_ACCEPTED=TRUE" >> /tmp/response.properties
  mkdir -p /opt/ibm
  chmod +x /tmp/ibm-java.bin
  /tmp/ibm-java.bin -i silent -f /tmp/response.properties
  ln -s /opt/ibm/java/jre/bin/* /usr/local/bin/
  echo -e "*** DONE ***\n"
}

# Install Nodejs
install_nodejs() {
  echo -e "\n*** install_nodejs ***\n"
  cd /tmp
  wget -q https://nodejs.org/dist/v6.7.0/node-v6.7.0-linux-s390x.tar.gz
  cd /usr/local && tar --strip-components 1 -xzf /tmp/node-v6.7.0-linux-s390x.tar.gz
  echo -e "*** DONE ***\n"
}

# Install Behave and its pre-requisites.  Firewall rules are also set.
setup_behave() {
  echo -e "\n*** setup_behave ***\n"
  # Setup Firewall Rules if they don't already exist
  grep -q '2375' <<< `iptables -L INPUT -nv`
  if [ $? != 0 ]; then
    iptables -I INPUT 1 -p tcp --dport 21212 -j ACCEPT
    iptables -I INPUT 1 -p tcp --dport 7050 -j ACCEPT
    iptables -I INPUT 1 -p tcp --dport 7051 -j ACCEPT
    iptables -I INPUT 1 -p tcp --dport 7053 -j ACCEPT
    iptables -I INPUT 1 -p tcp --dport 7054 -j ACCEPT
    iptables -I INPUT 1 -i docker0 -p tcp --dport 2375 -j ACCEPT
  fi

  # Install Behave Tests Pre-Reqs
  cd /tmp
  curl -s "https://bootstrap.pypa.io/get-pip.py" -o "get-pip.py"
  python get-pip.py > /dev/null 2>&1
  pip install -q --upgrade pip > /dev/null 2>&1
  pip install -q behave nose docker-compose > /dev/null 2>&1
  pip install -q -I flask==0.10.1 python-dateutil==2.2 pytz==2014.3 pyyaml==3.10 couchdb==1.0 flask-cors==2.0.1 requests==2.4.3 pyOpenSSL==16.2.0 pysha3 slugify ecdsa > /dev/null 2>&1
  pip install --upgrade six

  # Install protobuf and grpcio
  git clone https://github.com/grpc/grpc.git
  cd grpc
  pip install -rrequirements.txt
  git checkout tags/release-0_13_1
  sed -i -e "s/boringssl.googlesource.com/github.com\/linux-on-ibm-z/" .gitmodules
  git submodule sync
  git submodule update --init
  cd third_party/boringssl
  git checkout s390x-big-endian
  cd ../..
  GRPC_PYTHON_BUILD_WITH_CYTHON=1 pip install .
  echo -e "*** DONE ***\n"
}

# Update profile with environment variables required for Hyperledger Fabric use
# Also, clean up work directories and files
post_build() {
  echo -e "\n*** post_build ***\n"

  if ! test -e /etc/profile.d/goroot.sh; then
cat <<EOF >/etc/profile.d/goroot.sh
export GOROOT=$GOROOT
export GOPATH=$GOPATH
export PATH=\$PATH:$GOROOT/bin:$GOPATH/bin:/usr/local/bin
EOF

cat <<EOF >>/etc/environment
GOROOT=$GOROOT
GOPATH=$GOPATH
EOF

    if [ $OS_FLAVOR == "rhel" ] || [ $OS_FLAVOR == "sles" ]; then
cat <<EOF >>/etc/environment
CC=gcc
EOF
    fi
  fi

  if [ $OS_FLAVOR == "ubuntu" ]; then
    apt -y autoremove
  fi

  # Add non-root user to docker group
  BC_USER=`whoami`
  if [ $BC_USER != "root" ]; then
    sudo usermod -aG docker $BC_USER
  fi

  # Cleanup files and Docker images and containers
  rm -rf /tmp/*

  echo -e "Cleanup Docker artifacts\n"
  # Delete any temporary Docker containers created during the build process
  if [[ ! -z $(docker ps -aq) ]]; then
      docker rm -f $(docker ps -aq)
  fi

  echo -e "*** DONE ***\n"
}

################
# Main Routine #
################

# Check for help flags
if [ $# == 1 ] && ([[ $1 == "-h"  ||  $1 == "--help" || $1 == "-?" || $1 == "?" || -z $(grep "-" <<< $1) ]]); then
  usage
fi

# Ensure that the user running this script is root.
if [ xroot != x$(whoami) ]; then
  echo -e "\nERROR: You must be root to run this script.\n"
  exit 1
fi

# Determine Linux distribution
get_linux_flavor

# Install pre-reqs for detected Linux OS Distribution
prereq_$OS_FLAVOR

# Default action is to build all components for the Hyperledger Fabric environment
#if ! java -version > /dev/null 2>&1; then
#  install_java
#fi

#if ! node -v > /dev/null 2>&1; then
#  install_nodejs
#fi

if ! docker images > /dev/null 2>&1; then
  install_docker $OS_FLAVOR
fi

#if ! test -d /opt/go; then
#  install_golang $OS_FLAVOR
#else
#  export GOROOT=/opt/go
#fi

#build_hyperledger_fabric $OS_FLAVOR
#build_hyperledger_fabric-ca $OS_FLAVOR
#build_hyperledger_fabric-sdk-node $OS_FLAVOR


#if ! behave --version > /dev/null 2>&1; then
#  setup_behave
#fi

post_build

echo -e "\n\nDocker and its supporting components have been successfully installed.\n"
exit 0
