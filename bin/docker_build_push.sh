#!/bin/bash

TAG="$1"

cd /usr/local/fulcrum/docker/$TAG

sudo docker build -t fulcrum/$TAG .

sudo docker push fulcrum/$TAG

cd -
