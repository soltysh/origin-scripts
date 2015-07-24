#!/bin/bash

echo "Starting OpenShift..."
sudo /data/src/github.com/openshift/origin/_output/local/go/bin/openshift start &> logs/openshift.log &
sleep 10

echo "Exporting vars ..."
export CURL_CA_BUNDLE=$HOME/openshift.local.config/master/ca.crt
sudo chmod a+rwX $HOME/openshift.local.config/master/admin.kubeconfig

echo "Creating registry ..."
sudo chmod +r $HOME/openshift.local.config/master/openshift-registry.kubeconfig
oadm registry --latest-images --credentials=$HOME/openshift.local.config/master/openshift-registry.kubeconfig --config=$HOME/openshift.local.config/master/admin.kubeconfig

echo "Setting up policy ..."
oadm policy add-role-to-user view test-admin --config=$HOME/openshift.local.config/master/admin.kubeconfig

echo "Logging in ..."
oc login localhost:8443 -u test-admin -p pass --certificate-authority=$HOME/openshift.local.config/master/ca.crt

echo "Creating new project ..."
oc new-project test --display-name="OpenShift 3 Sample" --description="This is an example project to demonstrate OpenShift v3"

