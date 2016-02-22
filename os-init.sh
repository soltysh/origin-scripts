#!/bin/bash -e

echo "Starting OpenShift..."
# write config
sudo /data/src/github.com/openshift/origin/_output/local/bin/linux/amd64/openshift start \
    --write-config=$HOME/openshift.local.config \
    --etcd-dir=$HOME/openshift.local.etcd \
    --volume-dir=$HOME/openshift.local.volumes \
    --images="openshift/origin-\${component}:latest" &> /dev/null
# start openshift
loglevel=${1:-0}
sudo /data/src/github.com/openshift/origin/_output/local/bin/linux/amd64/openshift start \
  --master-config=$HOME/openshift.local.config/master/master-config.yaml \
  --node-config=$HOME/openshift.local.config/node-"$(hostname)"/node-config.yaml \
  --loglevel=$loglevel &> $HOME/logs/openshift.log &
sleep 10

echo "Exporting vars..."
export CURL_CA_BUNDLE=$HOME/openshift.local.config/master/ca.crt
sudo chmod a+rwX $HOME/openshift.local.config/master/admin.kubeconfig

echo "Creating registry..."
sudo chmod +r $HOME/openshift.local.config/master/openshift-registry.kubeconfig
oadm registry \
    --latest-images \
    --credentials=$HOME/openshift.local.config/master/openshift-registry.kubeconfig \
    --config=$HOME/openshift.local.config/master/admin.kubeconfig

echo "Creating router..."
sudo chmod +r $HOME/openshift.local.config/master/openshift-router.kubeconfig
echo '{"kind":"ServiceAccount","apiVersion":"v1","metadata":{"name":"router"}}' | oc create \
    -f - \
    --config=$HOME/openshift.local.config/master/admin.kubeconfig
oc get scc privileged -o json --config=$HOME/openshift.local.config/master/admin.kubeconfig \
    | sed '/\"users\"/a \"system:serviceaccount:default:router\",' \
    | oc replace scc privileged -f - --config=$HOME/openshift.local.config/master/admin.kubeconfig
oadm router --create --latest-images \
    --credentials=$HOME/openshift.local.config/master/openshift-router.kubeconfig \
    --config=$HOME/openshift.local.config/master/admin.kubeconfig \
    --service-account=router

echo "Allowing access to etcd..."
sudo chmod +r $HOME/openshift.local.config/master/master.etcd-client.key
sudo chmod +r $HOME/openshift.local.config/master/master.etcd-client.crt
sudo chmod +r $HOME/openshift.local.config/master/ca.crt

echo "Importing ImageStreams..."
set +e
release="centos7"
cat /etc/redhat-release | grep -q "Red Hat Enterprise Linux"
if [ $? -eq 0 ]; then
    release="rhel7"
fi
set -e
oc create \
    -f /data/src/github.com/openshift/origin/examples/image-streams/image-streams-"${release}".json \
    -n openshift  \
    --config=$HOME/openshift.local.config/master/admin.kubeconfig

echo "Setting up policy..."
oadm policy add-role-to-user view test-admin \
    --config=$HOME/openshift.local.config/master/admin.kubeconfig

echo "Logging in to OpenShift..."
oc login localhost:8443 \
    -u test-admin -p pass \
    --certificate-authority=$HOME/openshift.local.config/master/ca.crt

DOCKER_LOGIN=${DOCKER_LOGIN:-""}
if [ -n "${DOCKER_LOGIN}" ]; then
    echo "Logging in to docker registry..."
    registry=$(sudo /data/src/github.com/openshift/origin/_output/local/bin/linux/amd64/oc \
        --config=$HOME/openshift.local.config/master/admin.kubeconfig \
        --template='{{.spec.portalIP}}:{{(index .spec.ports 0).port}}' \
        get svc/docker-registry)
    set +e
    while true; do
        curl --max-time 2 -fs http://${registry}/healthz
        if [ $? -eq 0 ]; then
            break
        fi
        sleep 1
    done
    set -e
    token=$(oc whoami -t)
    docker login -u test-admin -e test@example.org -p ${token} ${registry}
fi

echo "Creating new project..."
oc new-project test \
    --display-name="OpenShift 3 Sample" \
    --description="This is an example project to demonstrate OpenShift v3"

