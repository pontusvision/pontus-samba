#!/bin/bash

PWD=`pwd`
DIR="$( cd "$(dirname "$0")" ; pwd -P )"
cd ${DIR}/docker

docker build  -t pontusvisiongdpr/samba:centos7  .

cd $PWD

