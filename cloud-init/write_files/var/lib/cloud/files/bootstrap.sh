#!/bin/bash

set -euo pipefail

install::docker() {
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | 
    apt-key add -
  add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
  
  apt-get install -y \
    docker-ce \
    docker-ce-cli \
    containerd.io

  systemctl start docker
  systemctl enable docker
}

install::nodejs() {
  bash -c "$(curl -sL https://deb.nodesource.com/setup_14.x)"

  curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg |
    sudo apt-key add -
  echo "deb https://dl.yarnpkg.com/debian/ stable main" | 
    sudo tee /etc/apt/sources.list.d/yarn.list
  
  apt-get install -y \
    nodejs \
    yarn
}

install::docker-compose() {
  local version binary
  version="$(
    curl -s https://api.github.com/repos/docker/compose/releases/latest | 
      grep "tag_name" | 
      cut -d \" -f4
  )"
  binary="docker-compose-$(uname -s)-$(uname -m)"

  curl \
    -L "https://github.com/docker/compose/releases/download/${version}/${binary}" \
    -o /usr/local/bin/docker-compose
  chmod 755 /usr/local/bin/docker-compose
}

iptables::rules() {
  # make sure the connections we are already using are matched, accepted,
  # and pulled out of the chain before reaching any DROP rules
  iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

  # open ports for ssh, http and https
  iptables -A INPUT -p tcp --dport 22 -j ACCEPT
  iptables -A INPUT -p tcp --dport 80 -j ACCEPT
  iptables -A INPUT -p tcp --dport 443 -j ACCEPT

  # allow loopback requests - inserted as first rule in chain
  iptables -I INPUT 1 -i lo -j ACCEPT

  # drop any packets that do not match the rest of the chain
  iptables -A INPUT -j DROP
}

hetzner::volume() {
  local volume
  volume="$(find /dev/disk/by-id/ -name '*_Volume_*' -print -quit)"
  [[ -n "${volume}" ]] || {
    echo "skip hetzner::volume - no externel volume found"
    return 0
  }
  local location="${1:-/home/user/docker}"

  mkfs.ext4 -F "${volume}"
  mkdir -p "${location}"
  mount -o discard,defaults "${volume}" "${location}"
  echo "${volume} "${location}" ext4 discard,nofail,defaults 0 0" >> /etc/fstab
}

main() {
  # verbose main function
  set -x

  # setup volume
  hetzner::volume

  # first update packages
  apt update -y
  apt upgrade -y
  
  # install components
  install::docker-compose
  install::nodejs
  install::docker

  # reload sysctl
  /sbin/sysctl --system
  # setup iptables rules
  iptables::rules

  # finishing bootstrap
  systemctl restart networking
}

# execute
[[ "${0}" != "${BASH_SOURCE[0]}" ]] || main "${@}"
