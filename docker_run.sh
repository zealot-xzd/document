#!/bin/bash
docker run --name rockylinux-dev --hostname=rockylinux-dev -p 12345:22 -p 8000:8000 --volume=/Users/zealot/Documents:/home/zealot --privileged --restart=no -t -d zealot/rockylinux  /usr/sbin/init
#docker run --name rockylinux-dev --hostname=rockylinux-dev -p 12345:22 -p 8000:8000 --volume=/Users/zealot/Documents:/home/zealot --privileged --restart=no -t -d rockylinux:9  bash
