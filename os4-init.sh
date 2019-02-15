#!/bin/bash -e

pushd /data/src/github.com/openshift/origin > /dev/null

echo "[INFO] Starting OpenShift control plane..."
screen -d -m \
    /data/src/github.com/openshift/origin/hack/local-up-master/master.sh
set +e
while true; do
    curl --max-time 2 -fs http://127.0.0.1:8443/healthz &>/dev/null
    if [[ $? -eq 0 ]]; then
        break
    fi
    sleep 1
done
set -e

echo "export KUBECONFIG=/data/src/github.com/openshift/origin/openshift.local.masterup/admin.kubeconfig"
