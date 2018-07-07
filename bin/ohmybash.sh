#!/usr/bin/env bash

# Purpose: Bash ultitilies
# Author : Ky-Anh Huynh
# License: MIT
# Date   : 2018 July 07

# Clean up containers that have random names
docker_containers_clean() {
  :
}

# Clean up all temporary Docker images
docker_images_clean() {
  while read -r _img; do
    echo >&2 ":: Removing no-name image $_img"
    docker rmi "$_img"
  done \
  < <(docker images | grep '<none>' | awk '{print $3}')
}
