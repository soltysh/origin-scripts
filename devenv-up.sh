#!/bin/bash

echo "[INFO] Starting NFS..."
sudo systemctl start nfs-server.service

echo "[INFO] Starting openshiftdev..."
virsh start openshiftdev
sleep 10

guest_ip="192.168.122.12"

echo "[INFO] Checking if $guest_ip is up..."

while true; do
    ssh -t -q x@$guest_ip "echo 2>&1"
    if [[ $? -eq 0 ]]; then
        break
    fi
    sleep 1
done

script_path=$(mktemp)

cat <<EOF > $script_path
echo "[INFO] Mounting origin..."
sudo mount 192.168.122.1:/nfsshare/origin /data/src/github.com/openshift/origin/

echo "[INFO] Mounting k8s..."
sudo mount 192.168.122.1:/nfsshare/kubernetes /data/src/k8s.io/kubernetes/
EOF

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
scp $GOPATH/src/github.com/soltysh/origin-scripts/!(devenv-up).sh x@$guest_ip:bin/
cat $script_path | ssh -t x@$guest_ip
rm -f ${script_path}

exec ssh x@$guest_ip
