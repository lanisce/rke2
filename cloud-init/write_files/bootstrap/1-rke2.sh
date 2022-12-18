#!/bin/bash

set -eo pipefail

iptables::rules() {
  # make sure the connections we are already using are matched, accepted,
  # and pulled out of the chain before reaching any DROP rules
  sudo iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

  # open ports for ssh, http and https
  sudo iptables -A INPUT -p tcp --dport 22 -j ACCEPT
  
  # rke ports
  # Kubernetes API
  sudo iptables -A INPUT -p tcp --dport 6443 -j ACCEPT
  # Kubernetes API
  sudo iptables -A INPUT -p tcp --dport 9345 -j ACCEPT
  # kubelet
  sudo iptables -A INPUT -p tcp --dport 10250 -j ACCEPT
  # etcd client port
  sudo iptables -A INPUT -p tcp --dport 2379 -j ACCEPT
  # etcd peer port
  sudo iptables -A INPUT -p tcp --dport 2380 -j ACCEPT
  # NodePort port range
  sudo iptables -A INPUT -p tcp --dport 30000:32767 -j ACCEPT

  # Required only for Flannel VXLAN
  sudo iptables -A INPUT -p tcp --dport 8472 -j ACCEPT
  # TODO replace with cilium ports
  # https://docs.cilium.io/en/v1.9/operations/system_requirements/

  # allow loopback requests - inserted as first rule in chain
  sudo iptables -I INPUT 1 -i lo -j ACCEPT

  # drop any packets that do not match the rest of the chain
  sudo iptables -A INPUT -j DROP
}

rke2::main() {
  # setups
  # iptables::rules

  # enable services
  systemctl enable rke2-agent.service
  systemctl start rke2-agent.service
}

# execute
[[ "${0}" != "${BASH_SOURCE[0]}" ]] || rke2::main
