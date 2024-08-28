#!/usr/bin/env bash

CRD_NAMESPACE_EXIST=`kubectl get namespace $1 2>&1`
if [[ $CRD_NAMESPACE_EXIST == *"(NotFound): namespaces"* ]]; then
  kubectl create namespace $1
  echo "crd namespace created as $1"
  sleep 10
  kubectl get namespace $1 2>&1
fi