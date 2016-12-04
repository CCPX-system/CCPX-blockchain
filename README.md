# CCPX-blockchain
Node.js application which provide functional API to CCPX-application to Hyperledger's blockchain network
This project based on LinuxOne server (s390x)

#Prerequisite
1. Make sure your Docker is ready (both CLI and service(s))
2. This bootstrap made for s390x. if you want to try with else, just focus on NODE.js dockerfile and change repo for node.

#Howto?
1) sudo -i
2) . start.sh
3) watching miracle ! 

#What will happen back there ?
1. Create Hyperledger network (at least 1 peer, 1 membersvrc)
2. Build go code on peer (go to .go dir and "go build .")
3. Access Peer's REST service (defualt port: 7050) to deploy that builded go code (Keep HASHCODE given after successfully deployed)
4. Start node.js application contains SDK (IBC)
5. For initialized, should comment deployed_name (HASHCODE for GO which you deployed)
6. SDK will download zip file which contain .go code which specify in SKD options to node_modules tmp
7. After first run SDK, please stop it and uncomment HASHCODE to embed HASHCODE to your request. Otherwise your function cannot do query on blockchain server
