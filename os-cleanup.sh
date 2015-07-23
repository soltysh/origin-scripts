#!/bin/bash

echo "Killing OpenShift..."
sudo pkill openshift

echo "Pruning docker..."
docker rmi $(docker images -q -f "dangling=true")
docker rm -f $(docker ps -qa)

echo "Pruning dirs..."
sudo rm -rf $HOME/openshift.local.*

