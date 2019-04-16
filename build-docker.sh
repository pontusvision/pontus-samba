#!/bin/bash

DIR="$( cd "$(dirname "$0")" ; pwd -P )"

docker build --rm  --no-cache -t pontusvisiongdpr/open-source-gdpr2.2:latest  ${DIR}/docker


