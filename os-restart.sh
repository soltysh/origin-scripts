#!/bin/bash

echo "Killing OpenShift..."
sudo pkill openshift

echo "Starting OpenShift..."
sudo /data/src/github.com/openshift/origin/_output/local/go/bin/openshift start \
  --master-config=$HOME/openshift.local.config/master/master-config.yaml \
  --node-config=$HOME/openshift.local.config/node-openshiftdev.local/node-config.yaml &> $HOME/logs/openshift.log &
