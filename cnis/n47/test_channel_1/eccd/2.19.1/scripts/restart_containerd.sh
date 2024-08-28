#!/usr/bin/env bash


worker_ips=$(kubectl get node -o wide | grep Ready | awk '{print $6}')

for worker in ${worker_ips}
do
    echo "restart containerd.service for   worker ${worker} ..."
    ssh -q -o StrictHostKeyChecking=no ${worker} "sudo systemctl restart containerd"
done
