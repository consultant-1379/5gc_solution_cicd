#!/usr/bin/env bash

# CHECK IF SERVICE ACCOUNT EXIST, IF NOT CREATE
SERVICE_ACCOUNT_EXIST=`kubectl get serviceaccount evnfm -n evnfm 2>&1`

if [[ $SERVICE_ACCOUNT_EXIST  == *"(NotFound): serviceaccounts"* ]]; then
  kubectl create -f /home/${1}/evnfm/common/ServiceAccount.yaml --namespace evnfm
  echo "service account created"
  sleep 10
  kubectl get serviceaccount evnfm -n evnfm 2>&1
fi