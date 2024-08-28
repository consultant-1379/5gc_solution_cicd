"""
    get_certificate.py
    Goal:
        get certificates to access/collect data
"""

import subprocess
import os
from datetime import datetime

from paramiko import SSHClient, AutoAddPolicy
import base64


# match given channel/node with respective host
def match_ssh_host(node):
    hosts = {"n47": "214.13.225.196",
             "n67": "n67-eccd1.sero.gic.ericsson.se",
             "n84": "10.117.60.6",
             "n89": "214.13.238.6"}
    return hosts[node]


# connect to test node/channel
def connect_to_server(node, ns):
    host = match_ssh_host(node)
    UN = 'eccd'
    PW = 'eccd'
    command = f"kubectl get secrets eric-cm-yang-provider-pm-query-client-cert --namespace {ns} -oyaml"

    # connect to the server
    client = SSHClient()
    client.set_missing_host_key_policy(AutoAddPolicy())
    client.connect(hostname=host, username=UN, password=PW)

    # get certificate
    stdin, stdout, stderr = client.exec_command(command)
    output = stdout.read().decode("utf-8")

    client.close()
    return output


# decode base64 encoded cert
def decode_cert(encoded_cert):
    decoded_cert = base64.urlsafe_b64decode(encoded_cert)
    decoded_cert_str = str(decoded_cert, "utf-8")
    return decoded_cert_str


# parse cert to cert and privkey and decode by calling decode_cert()
def parse_certificate(certificate):
    # parsing certificate to cert and privkey
    # find location of cert and privkey
    cert_loc = certificate.find("clientcert.pem")
    privkey_loc = certificate.find("clientprivkey.pem")
    end_loc = certificate.find("kind:")  # get location of "kind: " to know where privkey ends

    # parse certificate to isolate needed info (clientcert & clientprivkey)
    clientcert = certificate[cert_loc + len("clientcert.pem: "):privkey_loc].replace("\n", "")
    clientprivkey = certificate[privkey_loc + len("clientprivkey.pem: "):end_loc].replace("\n", "")

    # client.crt
    client_file = open(r'client.crt', 'w')
    client_file.write(decode_cert(clientcert))
    client_file.close()
    # private.key
    privkey_file = open(r'private.key', 'w')
    privkey_file.write(decode_cert(clientprivkey))
    privkey_file.close()


# TEMPORARY TESTING FUNCTION
# include format to get data
# TODO modify this or merge with data_collection.py to work with the script
def get_data():
    pod = r"{container=~\"eric-pc-mm-sctp\"\}"
    cmd = f"curl --cert client.crt --key private.key -k -X GET " \
          f"\"https://pcc-eric-pm-server.ingress.node89.sero.gic.ericsson.se/api/v1/query?query=avg(" \
          f"pmrm_container_cpu_usage_percent\{pod})&start=2023-08-03T08:00:00.781Z&end=2023-08-03T09:00:00.781Z&step" \
          f"=15s\" |/app/vbuild/RHEL7-x86_64/jq/1.5/bin/jq -r \'.data.result[0].value[1]\' "
    process_cmd = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, shell=True)
    out, err = process_cmd.communicate()
    print(cmd)
    print(str(out, "utf-8"))
    print(str(err, "utf-8"))


# call helper functions to get, decode, and store certificates
def make_certificate(node, ns):
    cert = connect_to_server(node, ns)
    parse_certificate(cert)
    # get_data()


# remove certificates after finish collecting data
def remove_certificate():
    os.remove("client.crt")
    os.remove("private.key")


# make_certificate("n89", "pcg")
# remove_certificate()
