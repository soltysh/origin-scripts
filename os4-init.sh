#!/bin/bash -e

pushd /data/src/github.com/openshift/origin > /dev/null

echo "[INFO] Starting OpenShift control plane..."
screen -d -m \
    /data/src/github.com/openshift/origin/hack/local-up-master/master.sh
set +e
while true; do
    curl --max-time 2 -kfs https://127.0.0.1:8443/healthz &>/dev/null
    if [[ $? -eq 0 ]]; then
        break
    fi
    sleep 1
done
set -e

mkdir -p $HOME/.kube/
while true; do
    if [ -f /data/src/github.com/openshift/origin/openshift.local.masterup/admin.kubeconfig ]; then
        cp /data/src/github.com/openshift/origin/openshift.local.masterup/admin.kubeconfig $HOME/.kube/config
        break
    fi
    sleep 1
done
