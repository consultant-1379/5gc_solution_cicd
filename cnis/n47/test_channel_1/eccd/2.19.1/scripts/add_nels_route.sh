#!/usr/bin/env bash


worker_ips=$(kubectl get node -o wide | grep Ready | awk '{print $6}')

for worker in ${worker_ips}
do
    echo "add nels route  for   worker ${worker} ..."
    ssh -q -o StrictHostKeyChecking=no ${worker} "sudo ip route add  10.221.14.88/32 via 214.13.225.193 dev app_ecfe_om"
done
