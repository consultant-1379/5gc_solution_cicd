#!/usr/bin/env bash


worker_ips=$(kubectl get node -o wide | grep Ready | awk '{print $6}')

for worker in ${worker_ips}
do
    echo "Add EVNFM registry certificate on worker ${worker} ..."
    scp -q -o StrictHostKeyChecking=no ./evnfm_root.crt ${worker}:~/evnfm_root.crt
    scp -q -o StrictHostKeyChecking=no ./evnfm_inter.crt ${worker}:~/evnfm_inter.crt
    ssh -q -o StrictHostKeyChecking=no ${worker} "sudo cp evnfm_*.crt /etc/pki/trust/anchors"
    ssh -q -o StrictHostKeyChecking=no ${worker} "sudo update-ca-certificates"
done
