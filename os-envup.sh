#!/bin/bash

images="docker.io/openshift/origin-sti-builder \
    docker.io/openshift/origin-custom-docker-builder \
    docker.io/openshift/origin-docker-builder \
    docker.io/openshift/origin-deployer \
    docker.io/openshift/hello-openshift \
    docker.io/openshift/origin-haproxy-router \
    docker.io/openshift/origin \
    docker.io/openshift/origin-pod \
    docker.io/openshift/origin-release \
    docker.io/openshift/origin-haproxy-router-base \
    docker.io/openshift/origin-base \
    docker.io/centos:centos7"

echo "Starting NFS..."
sudo systemctl start nfs-server.service
sudo firewall-cmd --add-service nfs

echo "Starting openshiftdev..."
virsh start openshiftdev
sleep 10

while [ -z "$guest_ip" ]; do
    guest_ip=$(arp -an | grep 52:54:00:f2:5e:34 | cut -f 2 -d "(" | cut -f 1 -d ")")
    sleep 1
done

echo "Checking if $guest_ip is up..."

while true; do
    ssh -t -q vagrant@$guest_ip "echo 2>&1"
    if [ $? -eq 0 ]; then
        break
    fi
    sleep 1
done

script_path=$(mktemp)

# sometimes I don't want to have the images to be pulled
if [ "$1" == "--fast" ]; then
cat <<EOF > $script_path
echo "Mounting origin..."
sudo mount 192.168.121.1:/nfsshare/origin /data/src/github.com/openshift/origin/

echo "Mounting k8s..."
sudo mount 192.168.121.1:/nfsshare/kubernetes /data/src/k8s.io/kubernetes/

os-cleanup.sh
EOF
else
cat <<EOF > $script_path
echo "Mounting origin..."
sudo mount 192.168.121.1:/nfsshare/origin /data/src/github.com/openshift/origin/

echo "Mounting k8s..."
sudo mount 192.168.121.1:/nfsshare/kubernetes /data/src/k8s.io/kubernetes/

echo "Pulling images..."
for img in $(echo $images); do
    docker pull \$img
done

os-cleanup.sh
EOF
fi

scp $GOPATH/src/github.com/soltysh/origin-scripts/* vagrant@$guest_ip:bin/
cat $script_path | ssh -t vagrant@$guest_ip
rm -f ${script_path}

exec ssh vagrant@$guest_ip
