#!/bin/bash

images="docker.io/openshift/origin \
    docker.io/openshift/origin-base \
    docker.io/openshift/origin-pod \
    docker.io/openshift/origin-deployer \
    docker.io/openshift/origin-docker-builder \
    docker.io/openshift/origin-sti-builder \
    docker.io/openshift/origin-haproxy-router \
    docker.io/openshift/origin-docker-registry \
    docker.io/openshift/origin-web-console \
    docker.io/openshift/hello-openshift"

echo "[INFO] Starting NFS..."
sudo systemctl start nfs-server.service
sudo firewall-cmd --add-service nfs

echo "[INFO] Starting openshiftdev..."
virsh start openshiftdev
sleep 10

while [[ -z "$guest_ip" ]]; do
    guest_ip=$(arp -an | grep 52:54:00:f2:5e:34 | cut -f 2 -d "(" | cut -f 1 -d ")")
    sleep 1
done

echo "[INFO] Checking if $guest_ip is up..."

while true; do
    ssh -t -q vagrant@$guest_ip "echo 2>&1"
    if [[ $? -eq 0 ]]; then
        break
    fi
    sleep 1
done

script_path=$(mktemp)

cat <<EOF > $script_path
echo "[INFO] Mounting origin..."
sudo mount 192.168.121.1:/nfsshare/origin /data/src/github.com/openshift/origin/

echo "[INFO] Mounting k8s..."
sudo mount 192.168.121.1:/nfsshare/kubernetes /data/src/k8s.io/kubernetes/
EOF

# sometimes I don't want to have the images to be pulled
if [ $# -eq 0 ]; then
    cat <<EOF >> $script_path
echo "[INFO] Pulling images..."
for img in $(echo $images); do
    while true; do
        docker pull \$img
        if [[ $? -eq 0 ]]; then
            break
        fi
    done
done
EOF
fi

cat <<EOF >> $script_path
echo "[INFO] Cleaning environment..."
os-cleanup.sh

echo "[INFO] Installing completions..."
sudo cp /data/src/github.com/openshift/origin/contrib/completions/bash/o* /etc/bash_completion.d/
EOF

if [ $# -eq 0 ]; then
    cat <<EOF >> $script_path
echo "[INFO] Upgrading system..."
sudo dnf upgrade -y
EOF
fi

shopt -s extglob
scp $GOPATH/src/github.com/soltysh/origin-scripts/!(os-envup).sh vagrant@$guest_ip:bin/
cat $script_path | ssh -t vagrant@$guest_ip
rm -f ${script_path}

exec ssh vagrant@$guest_ip
