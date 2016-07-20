#!/bin/bash

pushd /data/src/k8s.io/kubernetes > /dev/null

echo "[INFO] Checking for running k8s..."
curl --max-time 2 -fs http://127.0.0.1:8080/healthz
if [[ ! $? -eq 0 ]]; then
    echo "[INFO] Starting k8s..."
    screen -d -m /data/src/k8s.io/kubernetes/hack/local-up-cluster.sh -o _output/local/bin/linux/amd64/

    while true; do
        curl --max-time 2 -fs http://127.0.0.1:8080/healthz
        if [[ $? -eq 0 ]]; then
            break
        fi
        sleep 1
    done

    /data/src/k8s.io/kubernetes/_output/local/bin/linux/amd64/kubectl \
        config set-cluster local
        --server=http://127.0.0.1:8080
        --insecure-skip-tls-verify=true
    /data/src/k8s.io/kubernetes/_output/local/bin/linux/amd64/kubectl \
        config set-context local
        --cluster=local
    /data/src/k8s.io/kubernetes/_output/local/bin/linux/amd64/kubectl \
        config use-context local
fi

/data/src/k8s.io/kubernetes/_output/local/bin/linux/amd64/ginkgo \
    -focus="$@" \
    ./_output/local/go/bin/e2e.test -- \
    --provider=local \
    --kubeconfig=/home/vagrant/.kube/config \
    --host=http://127.0.0.1:8080 \
