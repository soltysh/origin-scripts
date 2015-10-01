#!/bin/bash -e

echo "Killing OpenShift..."
sudo pkill openshift

echo "Starting OpenShift..."
sudo /data/src/github.com/openshift/origin/_output/local/bin/linux/amd64/openshift start \
  --master-config=$HOME/openshift.local.config/master/master-config.yaml \
  --node-config=$HOME/openshift.local.config/node-openshiftdev.local/node-config.yaml &> $HOME/logs/openshift.log &
sleep 5
