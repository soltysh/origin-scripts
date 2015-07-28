#!/bin/bash

echo "Killing OpenShift..."
sudo pkill openshift

echo "Pruning docker..."
docker rmi $(docker images -q -f "dangling=true")
docker rm -f $(docker ps -qa)

echo "Umounting dirs..."
mount | grep openshift.local.volumes | cut -f 3 -d " " | xargs sudo umount

echo "Pruning dirs..."
sudo rm -rf $HOME/openshift.local.*
