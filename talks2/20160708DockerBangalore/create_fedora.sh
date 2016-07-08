#!/bin/bash

set -x

docker pull fedora
echo "
FROM fedora
RUN dnf install -y iproute net-tools iputils && setcap cap_net_admin,cap_net_raw+p /usr/bin/ping
" >  Dockerfile

docker build -t fedora:my .
