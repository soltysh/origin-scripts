#!/bin/bash

echo "[INFO] Killing OpenShift..."
sudo pkill openshift

echo "[INFO] Pruning docker..."
docker rm -f $(docker ps -qa)
docker rmi $(docker images -q -f "dangling=true")
docker rmi $(docker images --no-trunc | grep 172.30 | awk '{print $3}')

echo "[INFO] Umounting dirs..."
mount | grep -E "(openshift.local.volumes|test-extended)" | cut -f 3 -d " " | xargs sudo umount

echo "[INFO] Pruning dirs..."
sudo rm -rf $HOME/openshift.local.*
sudo rm -rf $HOME/logs/*
sudo rm -rf $HOME/.kube
