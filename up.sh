#!/bin/bash

if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi

# Source all up.sh - scripts in subfolders
for up in $(find -maxdepth 2 -mindepth 2 -executable -name up.sh); do
  source "$up"
done

sysctl -w vm.max_map_count=262144
docker-compose up --build
