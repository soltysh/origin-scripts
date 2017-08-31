#!/bin/bash -e

pushd /data/src/k8s.io/kubernetes > /dev/null

echo "[INFO] Starting k8s..."
export KUBELET_FLAGS="--fail-swap-on=false"
screen -d -m sudo "KUBELET_FLAGS=$KUBELET_FLAGS" "PATH=$PATH" \
    /data/src/k8s.io/kubernetes/hack/local-up-cluster.sh \
    -o _output/local/bin/linux/amd64/
set +e
while true; do
    curl --max-time 2 -fs http://127.0.0.1:8080/healthz &>/dev/null
    if [[ $? -eq 0 ]]; then
        break
    fi
    sleep 1
done
set -e

sudo chmod +r /var/run/kubernetes/server-ca.crt
sudo chmod +r /var/run/kubernetes/client-admin.crt
sudo chmod +r /var/run/kubernetes/client-admin.key

echo "[INFO] Initiating kubectl..."
/data/src/k8s.io/kubernetes/_output/local/bin/linux/amd64/kubectl \
    config set-cluster local \
    --server=https://localhost:6443 \
    --certificate-authority=/var/run/kubernetes/server-ca.crt
/data/src/k8s.io/kubernetes/_output/local/bin/linux/amd64/kubectl \
    config set-credentials myself \
    --client-key=/var/run/kubernetes/client-admin.key \
    --client-certificate=/var/run/kubernetes/client-admin.crt
/data/src/k8s.io/kubernetes/_output/local/bin/linux/amd64/kubectl \
    config set-context local \
    --cluster=local \
    --user=myself
/data/src/k8s.io/kubernetes/_output/local/bin/linux/amd64/kubectl \
    config use-context local
