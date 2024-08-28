#!/usr/bin/env bash

UI_USER="$1"
UI_PASS="$2"
SEC_HOST="$3"

# CHECK IF IAM admin USERS SECRET EXIST, IF NOT CREATE
SECRET_EXIST=`kubectl get secret eric-sec-access-mgmt-creds -n evnfm 2>&1`

if [[ $SECRET_EXIST  == *"(NotFound): secrets"* ]]; then
  kubectl create -f /home/eccd/evnfm/common/passwords.yaml --namespace evnfm
  echo "iam admin user secret created"
  sleep 10
  kubectl get secret eric-sec-access-mgmt-creds -n evnfm 2>&1
fi

# CHECK IF Postgres admin USERS SECRET EXIST, IF NOT CREATE
SECRET_EXIST=`kubectl get secret eric-eo-database-pg-secret -n evnfm 2>&1`

if [[ $SECRET_EXIST  == *"(NotFound): secrets"* ]]; then
  kubectl create -f /home/eccd/evnfm/common/postgres_passwords.yaml --namespace evnfm
  echo "Postgres admin user secret created"
  sleep 10
  kubectl get secret eric-eo-database-pg-secret -n evnfm 2>&1
fi

# CHECK IF eric-oss-lm-combined-server-db-pg-secret SECRET EXIST, IF NOT CREATE
#LM_SECRET_EXIST=`kubectl get secret eric-oss-lm-combined-server-db-pg-secret -n evnfm 2>&1`

#if [[ $LM_SECRET_EXIST  == *"(NotFound): secrets"* ]]; then
#  kubectl create -f /home/eccd/evnfm/common/lmcombined_passwords.yaml --namespace evnfm
#  echo "eric-oss-lm-combined-server-db-pg-creds secret created"
#  sleep 10
#  kubectl get secret eric-oss-lm-combined-server-db-pg-secret -n evnfm 2>&1
#fi

# CHECK IF CONTAINER REGISTRY SECRET EXIST, IF NOT CREATE
SECRET_EXIST=`kubectl get secret container-registry-users-secret -n evnfm 2>&1`

if [[ $SECRET_EXIST  == *"(NotFound): secrets"* ]]; then
  htpasswd -cBb /home/eccd/evnfm/common/htpasswd.txt "$UI_USER" "$UI_PASS"
  kubectl create secret generic container-registry-users-secret --from-file=htpasswd=/home/eccd/evnfm/common/htpasswd.txt --namespace evnfm
  rm -f htpasswd.txt
  echo "container registry user secret created"
  sleep 10
  kubectl get secret container-registry-users-secret -n evnfm 2>&1
  sleep 10
  kubectl create secret generic container-credentials --from-literal=url="$SEC_HOST" --from-literal=userid="$UI_USER" --from-literal=userpasswd="$UI_PASS"  --namespace evnfm
  echo "container-credentials created"
fi