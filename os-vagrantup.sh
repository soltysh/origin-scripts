#!/bin/bash

cd $GOPATH/src/github.com/openshift/origin

echo "[INFO] Starting openshiftdev..."
vagrant origin-init --stage inst --os rhel7 --instance-type c4.large maszulik-dev
vagrant up --provider aws
vagrant sync-origin -s

guest_ip=$(vagrant ssh-config | grep HostName | awk '{ print $2 }')
guest_ip="ec2-${guest_ip//./-}.compute-1.amazonaws.com"

scp $GOPATH/src/github.com/soltysh/origin-scripts/* $guest_ip:
exec ssh $guest_ip
