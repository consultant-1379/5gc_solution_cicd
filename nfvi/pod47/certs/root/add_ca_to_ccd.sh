#!/usr/bin/env bash

if [[ $# -gt 0 ]]
then
    echo "This script is used to add Team Blues Root CA to all the nodes in the CCD cluster."
    echo "Please run on the director node." 
    echo "Example: ./add_ca_to_ccd.sh"
    exit 0
fi

echo -n "Add Team Blues Root CA on director ..."
sudo cp RootCA.crt /etc/pki/trust/anchors/
sudo update-ca-certificates
echo "done"

node_ips=$(kubectl get node -o wide | grep -v NAME | awk '{print $6}')

for node in ${node_ips}
do
    echo -n "Add Team Blues Root CA on node ${node} ..."
    scp -q -o StrictHostKeyChecking=no RootCA.crt ${node}:~/
    ssh -q -o StrictHostKeyChecking=no ${node} "sudo mv ~/RootCA.crt /etc/pki/trust/anchors/"
    ssh -q -o StrictHostKeyChecking=no ${node} "sudo update-ca-certificates"
    echo "done"
done
