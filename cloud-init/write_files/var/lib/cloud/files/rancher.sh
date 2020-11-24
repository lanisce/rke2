#!/bin/bash

set -euo pipefail

main() {
  # get source
  git clone https://github.com/lanisce/rancher.git "/home/user/github/lanisce/rancher"
  cd "${_}"

  # start it up
  docker-compose up -d
}

# execute
[[ "${0}" != "${BASH_SOURCE[0]}" ]] || main "${@}"
