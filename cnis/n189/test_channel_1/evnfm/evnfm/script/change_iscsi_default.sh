#!/usr/bin/env bash

# CHECK IF network-block-iscsi storage is default or not, IF NOT change it to default
iscsi_exist=`kubectl get storageClass |grep network-block-iscsi ;true`
iscsi_exist_rc=`kubectl get storageClass |grep -q network-block-iscsi ;echo $?`
iscsi_default=`kubectl get storageClass |grep default |awk '{print $1}'`
iscsi_default_rc=`kubectl get storageClass |grep -q default ;echo $?`
if [ ${iscsi_exist_rc} -eq 0 ]; then
    echo "network-block-iscsi storage Class is already created."
    if [ ${iscsi_default_rc} != 0 ] || [ ${iscsi_default} == "network-file" ]; then
        echo "network-block-iscsi storage Class is not default. Changing to default"
        kubectl patch storageclass network-block-iscsi -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}' ;true
        kubectl patch storageclass network-file -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"false"}}}' ;true
    fi
    echo ${iscsi_exist}
else
    kubectl create -f /home/${1}/evnfm/certificates/storageclass_iscsi.yaml ;true
    kubectl patch storageclass network-block-iscsi -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}' ;true
    kubectl patch storageclass network-file -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"false"}}}' ;true
    echo ${iscsi_exist}
fi
