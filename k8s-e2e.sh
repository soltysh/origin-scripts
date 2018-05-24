#!/bin/bash

pushd /data/src/k8s.io/kubernetes > /dev/null

echo "[INFO] Checking for running k8s..."
curl --max-time 2 -fs http://127.0.0.1:8080/healthz
if [[ ! $? -eq 0 ]]; then
    k8s-init.sh
fi

/data/src/k8s.io/kubernetes/_output/local/bin/linux/amd64/ginkgo \
    -focus="$@" \
    ./_output/local/go/bin/e2e.test -- \
    --provider=local \
    --kubeconfig=$HOME/.kube/config \
    --host=http://127.0.0.1:8080
