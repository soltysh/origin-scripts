#!/bin/bash -e

echo "[INFO] Logging in to docker registry..."
registry=$(sudo /data/src/github.com/openshift/origin/_output/local/bin/linux/amd64/oc \
    --config=$HOME/openshift.local.config/master/admin.kubeconfig \
    --template='{{.spec.portalIP}}:{{(index .spec.ports 0).port}}' \
    get svc/docker-registry)
set +e
while true; do
    curl --max-time 2 -fs http://${registry}/healthz
    if [[ $? -eq 0 ]]; then
        break
    fi
    sleep 1
done
set -e
token=$(oc whoami -t)
docker login -u test-admin -e test@example.org -p ${token} ${registry}
echo ${registry}
