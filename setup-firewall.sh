#!/bin/bash

# Get the Docker network subnet and Squid container IP
SUBNET=$(docker network inspect assistant-sandbox_sandbox_net --format '{{(index .IPAM.Config 0).Subnet}}')
SQUID_IP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $(docker-compose ps -q squid))

echo "Setting up firewall rules for subnet: $SUBNET, Squid IP: $SQUID_IP"

docker run --rm --privileged --network host --pid host ubuntu \
  bash -c "apt update && apt install -y iptables && \
           iptables -A DOCKER-USER -s $SUBNET -d $SQUID_IP  -p tcp --dport 3128 -j ACCEPT && \
           iptables -A DOCKER-USER -s $SUBNET -d $SUBNET    -j ACCEPT && \
           iptables -A DOCKER-USER -s $SUBNET               -j DROP"

echo "Firewall rules applied successfully"
