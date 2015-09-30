#!/bin/bash

echo "Killing OpenShift..."
sudo pkill openshift

echo "Pruning docker..."
docker rmi $(docker images -q -f "dangling=true")
docker rm -f $(docker ps -qa)
docker rmi $(docker images --no-trunc | grep 172.30 | awk '{print $3}')

echo "Umounting dirs..."
mount | grep openshift.local.volumes | cut -f 3 -d " " | xargs sudo umount

echo "Pruning dirs..."
sudo rm -rf $HOME/openshift.local.*
sudo rm -rf $HOME/logs/*
