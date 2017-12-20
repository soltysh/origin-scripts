#!/bin/bash -e

function patchcmd {
    local version="$(openshift version | grep '^openshift v' | awk -F 'v' '{print $2}')"
    local semver=(${version//./ })
    local major="${semver[0]}"
    local minor="${semver[1]}"

    if [[ "$major" -le "3" ]] && [[ "$minor" -lt "8" ]]; then
	echo "openshift"
    else
	echo "oc"
    fi
}

function patchconfig {
    local file=$1
    local patch_content=$2
    local patch_type=${3:-strategic}
    local tmpfile=$(mktemp)

    sudo cp $file $tmpfile

    sudo /data/src/github.com/openshift/origin/_output/local/bin/linux/amd64/$(patchcmd) ex config patch \
	 --type=${patch_type} \
	 $tmpfile \
	 --patch=${patch_content} | sudo tee $file >/dev/null

    sudo rm $tmpfile
}

echo "[INFO] Starting OpenShift..."
# write config
sudo /data/src/github.com/openshift/origin/_output/local/bin/linux/amd64/openshift start \
    --write-config=$HOME/openshift.local.config \
    --etcd-dir=$HOME/openshift.local.etcd \
    --volume-dir=$HOME/openshift.local.volumes \
    --latest-images \
    --images="openshift/origin-\${component}:\${version}" &> /dev/null
# replace subdomain configuration
server_ip=$(ip -o -4 addr show up primary scope global dynamic | awk '{print $4}' | cut -f1  -d'/')
patchconfig $HOME/openshift.local.config/master/master-config.yaml '{"routingConfig":{"subdomain":"'"${server_ip}"'.nip.io"}}'
patchconfig $HOME/openshift.local.config/node-"$(hostname)"/node-config.yaml '{"kubeletArguments":{"image-gc-high-threshold":["99"]}}'
# start openshift
loglevel=${1:-0}
mkdir -p $HOME/logs
sudo /data/src/github.com/openshift/origin/_output/local/bin/linux/amd64/openshift start \
    --master-config=$HOME/openshift.local.config/master/master-config.yaml \
    --node-config=$HOME/openshift.local.config/node-"$(hostname)"/node-config.yaml \
    --loglevel=$loglevel &> $HOME/logs/openshift.log &
set +e
while true; do
    curl --max-time 2 -kfs https://localhost:8443/healthz &>/dev/null
    if [[ $? -eq 0 ]]; then
        break
    fi
    sleep 1
done
set -e

echo "[INFO] Exporting vars..."
export CURL_CA_BUNDLE=$HOME/openshift.local.config/master/ca.crt
sudo chmod a+rwX $HOME/openshift.local.config/master/admin.kubeconfig

echo "[INFO] Creating registry..."
oc adm registry \
    --images="openshift/origin-\${component}:\${version}" \
    --latest-images \
    --namespace=default \
    --config=$HOME/openshift.local.config/master/admin.kubeconfig

echo "[INFO] Creating router..."
oc adm policy add-scc-to-user hostnetwork system:serviceaccount:default:router \
    --config=$HOME/openshift.local.config/master/admin.kubeconfig
oc adm router \
    --images="openshift/origin-\${component}:\${version}" \
    --latest-images \
    --service-account=router \
    --config=$HOME/openshift.local.config/master/admin.kubeconfig

echo "[INFO] Allowing access to etcd..."
sudo chmod +r $HOME/openshift.local.config/master/master.etcd-client.key
sudo chmod +r $HOME/openshift.local.config/master/master.etcd-client.crt
sudo chmod +r $HOME/openshift.local.config/master/ca.crt

set +e
while true; do
    oc get namespace/openshift \
    --config=$HOME/openshift.local.config/master/admin.kubeconfig &>/dev/null
    if [[ $? -eq 0 ]]; then
        break
    fi
    sleep 1
done
release="centos7"
cat /etc/redhat-release | grep -q "Red Hat Enterprise Linux"
if [[ $? -eq 0 ]]; then
    release="rhel7"
fi
set -e

echo "[INFO] Creating prometheus..."
oc new-app \
    -f /data/src/github.com/openshift/origin/examples/prometheus/prometheus.yaml \
    --config=$HOME/openshift.local.config/master/admin.kubeconfig

echo "[INFO] Importing ImageStreams..."
oc create \
    -f /data/src/github.com/openshift/origin/examples/image-streams/image-streams-"${release}".json \
    --namespace=openshift  \
    --config=$HOME/openshift.local.config/master/admin.kubeconfig

echo "[INFO] Setting up policy..."
oc adm policy add-role-to-user view test-admin \
    --namespace=kube-system \
    --config=$HOME/openshift.local.config/master/admin.kubeconfig
oc adm policy add-role-to-user view test-admin \
    --namespace=default \
    --config=$HOME/openshift.local.config/master/admin.kubeconfig

echo "[INFO] Logging in to OpenShift..."
oc login localhost:8443 \
    -u test-admin -p pass \
    --certificate-authority=$HOME/openshift.local.config/master/ca.crt

echo "[INFO] Creating new project..."
oc new-project test \
    --display-name="OpenShift 3 Sample" \
    --description="This is an example project to demonstrate OpenShift v3"

