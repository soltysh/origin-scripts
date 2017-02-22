#!/bin/bash

pushd /data/src/k8s.io/kubernetes > /dev/null

echo "[INFO] Starting k8s..."
export RUNTIME_CONFIG="batch/v2alpha1=true"
screen -d -m sudo "PATH=$PATH" /data/src/k8s.io/kubernetes/hack/local-up-cluster.sh -o _output/local/bin/linux/amd64/

while true; do
    curl --max-time 2 -fs http://127.0.0.1:8080/healthz &>/dev/null
    if [[ $? -eq 0 ]]; then
        break
    fi
    sleep 1
done

echo "[INFO] Initiating kubectl..."
/data/src/k8s.io/kubernetes/_output/local/bin/linux/amd64/kubectl \
    config set-cluster local \
    --server=http://127.0.0.1:8080 \
    --insecure-skip-tls-verify=true
/data/src/k8s.io/kubernetes/_output/local/bin/linux/amd64/kubectl \
    config set-context local \
    --cluster=local
/data/src/k8s.io/kubernetes/_output/local/bin/linux/amd64/kubectl \
    config use-context local
