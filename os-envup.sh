#!/bin/bash

images="docker.io/openshift/sti-image-builder \
    docker.io/openshift/origin-sti-builder \
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

virsh start openshiftdev
sleep 5

guest_ip=$(arp -an | grep 52:54:00:be:6e:81 | cut -f 2 -d "(" | cut -f 1 -d ")")

script_path=$(mktemp)
cat <<EOF > $script_path
echo "Mounting origin..."
sudo mount -t 9p -o trans=virtio,version=9p2000.L /mnt/origin /data/src/github.com/openshift/origin/

echo "Pruning docker..."
docker rmi $(docker images -q -f "dangling=true")
docker rm -f $(docker ps -qa)

echo "Pulling images..."
for img in $(echo $images); do
    docker pull \$img
done
EOF

scp $GOPATH/src/github.com/soltysh/origin-scripts/* vagrant@$guest_ip:bin/
cat $script_path | ssh -t vagrant@$guest_ip
rm -f ${script_path}

exec ssh vagrant@$guest_ip
