#!/usr/bin/env bash

# CHECK IF CLUSTER ROLE BINDING SECRET EXIST, IF NOT CREATE
CLUSTER_ROLE_BINDING_EXIST=`kubectl get clusterrolebindings evnfm 2>&1`
if [[ $CLUSTER_ROLE_BINDING_EXIST == *"(NotFound): clusterrolebindings.rbac.authorization.k8s.io"* ]]; then
  kubectl create -f /home/${1}/evnfm/common/ClusterRoleBinding.yaml
  echo "cluster role binding created"
  sleep 10
  kubectl get clusterrolebindings evnfm 2>&1
fi