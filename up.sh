#!/bin/bash

# Source all up.sh - scripts in subfolders
for up in $(find -maxdepth 2 -mindepth 2 -executable -name up.sh); do
  source "$up"
done

sudo docker-compose up 

