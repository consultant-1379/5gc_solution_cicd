#!/usr/bin/env bash

# CHECK IF CLUSTER ROLE BINDING SECRET EXIST, IF NOT CREATE
NAMESPACE_EXIST=`kubectl get namespace evnfm 2>&1`

if [[ $NAMESPACE_EXIST == *"(NotFound): namespaces"* ]]; then
  kubectl create namespace evnfm
  echo "evnfm namespace created"
  sleep 10
  kubectl get namespace evnfm 2>&1
fi

# Disable it without ICCR
CRD_NAMESPACE_EXIST=`kubectl get namespace $1 2>&1`
T
if [[ $CRD_NAMESPACE_EXIST == *"(NotFound): namespaces"* ]]; then
  kubectl create namespace $1
  echo "crd namespace created"
  sleep 10
  kubectl get namespace $1 2>&1
fi