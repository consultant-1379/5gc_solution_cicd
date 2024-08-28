#!/usr/bin/env bash

if [[ "$#" != "1" ]]; then
    echo "Error: Wrong number of arguments"
    echo "Usage: add_evnfm_cert.sh <evnfm_registry> <registry_cert_file>"
    echo "Example: ./add_evnfm_cert.sh evnfm-docker-registry.ingress.n84-eccd2.sero.gic.ericsson.se"
    echo "         ./add_evnfm_cert.sh evnfm-docker-registry.ingress.n28-eccd2.sero.gic.ericsson.se"
    echo "         ./add_evnfm_cert.sh evnfm-docker-registry.ingress.n99-eccd2.sero.gic.ericsson.se"
    exit 1
fi

evnfm_registry=$1
worker_ips=$(kubectl get node -o wide | grep worker | awk '{print $6}')

for worker in ${worker_ips}
do
    echo "Add EVNFM registry certificate on worker ${worker} ..."
    scp -q -o StrictHostKeyChecking=no ../certs/TeamBluesRootCA.crt ${worker}:~/ca.crt
    ssh -q -o StrictHostKeyChecking=no ${worker} "sudo mkdir -p /etc/docker/certs.d/${evnfm_registry}"
    ssh -q -o StrictHostKeyChecking=no ${worker} "sudo cp ca.crt /etc/docker/certs.d/${evnfm_registry}"
done
