#!/bin/bash

set -euo pipefail

source /bootstrap/.env

main() {
  # add rke2 server to hosts
  echo "${RKE2_SERVER} rke2.local" | sudo tee -a /etc/hosts

  # mount eBPF fs (req. cilium)
  sudo mount bpffs -t bpf /sys/fs/bpf

  # install rke2
  sudo sh -c "$(curl -sfL https://get.rke2.io)"

  # reset network config
  sudo netplan generate &&
    sudo netplan apply
}

# execute
[[ "${0}" != "${BASH_SOURCE[0]}" ]] || main
