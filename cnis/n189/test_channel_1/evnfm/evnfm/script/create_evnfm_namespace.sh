#!/usr/bin/env bash

# CHECK IF CLUSTER ROLE BINDING SECRET EXIST, IF NOT CREATE
NAMESPACE_EXIST=`kubectl get namespace evnfm 2>&1`

if [[ $NAMESPACE_EXIST == *"(NotFound): namespaces"* ]]; then
  kubectl create namespace evnfm
  echo "evnfm namespace created"
  sleep 10
  kubectl get namespace evnfm 2>&1
fi