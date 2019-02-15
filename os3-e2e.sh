#!/bin/bash

pushd /data/src/github.com/openshift/origin/test/extended > /dev/null

echo "[INFO] Checking for running OpenShift..."
curl --max-time 2 -kfs https://localhost:8443/healthz &>/dev/null
if [[ ! $? -eq 0 ]]; then
    os-init.sh

    while true; do
        curl --max-time 2 -kfs https://localhost:8443/healthz &>/dev/null
        if [[ $? -eq 0 ]]; then
            break
        fi
        sleep 1
    done
fi

KUBECONFIG=$HOME/openshift.local.clusterup/kube-apiserver/admin.kubeconfig \
    EXTENDED_TEST_PATH=/data/src/github.com/openshift/origin/test/extended \
    /data/src/github.com/openshift/origin/_output/local/bin/linux/amd64/ginkgo \
    -focus="$@" \
    /data/src/github.com/openshift/origin/_output/local/bin/linux/amd64/extended.test
