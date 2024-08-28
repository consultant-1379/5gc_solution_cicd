#! /usr/bin/python

import json
import requests
import sys
import os
import getopt

from requests.packages.urllib3.exceptions import InsecureRequestWarning
requests.packages.urllib3.disable_warnings(InsecureRequestWarning)

#Configure which type of NF to check status for:
nfs = ["AMF", "SMF", "PCF", "AUSF", "UDR", "UDM", "NSSF", "NEF"]

# if the 2 ENV does not exist ,return the default value 'null'
client_cert = os.getenv('CLIENT_CERT','null')
client_priv_key = os.getenv('CLIENT_KEY', 'null')

# NRF FQDN and port
ip = "nrf-fqdn"
port = 81

#Flag for deleting the 'SUSPEND' NF or not
del_suspend_nf=False
#Flag for showing the detailed NF info or not 
show_all=False

def usage():
  print "Usage: run it on nodelocal-api.eccd.local \n"
  print "export CLIENT_CERT=<Client Cert>"
  print "export CLIENT_KEY=<Client Key>"
  print "./nrf_status.py -H <nrf_fqdn> -P <nrf_port> \n"
  print "Print ALL the info: ./nrf_status.py -H <nrf_fqdn> -P <nrf_port> -A\n"
  print "Example: > export CLIENT_CERT=/home/eccd/ccxx/client.crt;export CLIENT_KEY=/home/eccd/ccxx/client.key; ~/ccxx/nrf_status_mtls.py -H nrf1.n47.5gc.mnc081.mcc240.3gppnetwork.org -P 443 -A"
  print "Usage to delete suspended nodes: ./nrf_status.py -H <nrf-ip> -P <nrf-port> -d"


try:
  opts, args = getopt.getopt(sys.argv[1:], "hdAH:P:",["help", "delete","All","fqdn=", "port="])
except:
  print "   ERROR : get the parameters failed!"
  usage()  
  sys.exit(2)

for opt, arg in opts: 
  if opt in ("-h", "--help"):
    usage()
    sys.exit()
  elif opt in ("-d","--delete"):
    del_suspend_nf=True
  elif opt in ("-A", "--All"):
    show_all=True
  elif opt in ("-H", "--host"):
    ip = arg
  elif opt in ("-P", "--port"):
    port = arg
  else:
    print ("  WARNING: wrong param "+ opt) 
    usage()
    sys.exit(1)

# check the argument number and if certificate and Client Key for TLS exist or not
if client_cert == 'null' or  client_priv_key == 'null':
  usage()

# print the usage/help information
def usage():
  print "Usage:\n"
  print "export CLIENT_CERT=<Client Cert>"
  print "export CLIENT_KEY=<Client Key>"
  print "./nrf_status.py -H <nrf_fqdn> -P <nrf_port> \n"
  print "Print ALL the info: ./nrf_status.py -H <nrf_fqdn> -P <nrf_port> -A\n"
  print "Usage to delete suspended nodes: ./nrf_status.py -H <nrf-ip> -P <nrf-port> -d"

# to decide if print the detailed registered infomation
client_cert = os.getenv('CLIENT_CERT','null')
client_priv_key = os.getenv('CLIENT_KEY')
print os.getenv('CLIENT_CERT')

# Status printout scenario
if not del_suspend_nf:
  for nf in nfs:
    try:
      list = requests.get('https://' + ip + ':' + port + '/nnrf-nfm/v1/nf-instances?nf-type=' + nf + '', verify=False,cert=(client_cert, client_priv_key))
      #print list
      json_data=list.json()
      #print json_data, "#####."
    except:
      exit ("  ERROR: Unable to reach NRF using IP: " + ip + "!")
    print (nf)
    if list.json()['_links']['item'] == []:
      print ("  WARNING: No " + nf + " found in NRF!")
    else:
      for x in list.json()['_links']['item']:
        url = x['href']
        result = requests.get(url, verify=False,cert=(client_cert, client_priv_key))
        print "  " + result.json()['nfInstanceId']
        print "  - " + "nfStatus" + " " + result.json()['nfStatus']
        if (nf == "NEF"):
          break
        for service in result.json()['nfServices']:
          print "  - " + service['serviceName'] + " "+  service['nfServiceStatus']
          if (nf == "SMF"):
            print "  - " + 'fqdn' + " " +  service['fqdn'].split('.')[1]
        if (nf == "AMF"):
          print "  - " + "fqdn" + " " + result.json()['fqdn'].split('.')[0]
        # print all the detailed registered NF info
        if show_all:
          print "***************" + nf + "**********************"
          print json.dumps(result.json(), sort_keys=True, indent=2)
          print "***************" + nf + " END (don't use -A param if you don't like the detailed info)******************\n\n"

# Deleting suspended NFs scenario
else: 
  count = 0
  for nf in nfs:
    try:
      list = requests.get('https://' + ip + ':' + port + '/nnrf-nfm/v1/nf-instances?nf-type=' + nf + '',  verify=False,cert=(client_cert, client_priv_key))
      #json_data=list.json()
      #print json_data, "#####."
    except:
      exit ("  ERROR: Unable to reach NRF using IP: " + ip + "!")
    #print (nf)
    try:
      for x in list.json()['_links']['item']:
        url = x['href']
        result = requests.get(url, verify=False,cert=(client_cert, client_priv_key))
        print "  " + result.json()['nfInstanceId']
        print "  - " + "nfStatus" + " " + result.json()['nfStatus']
        if result.json()['nfStatus'] == "SUSPENDED":
          print "Deleting " + nf + " with ID: " + result.json()['nfInstanceId']
          result = requests.delete('https://' + ip + ':' + port + '/nnrf-nfm/v1/nf-instances/' + result.json()['nfInstanceId'] + '', verify=False,cert=(client_cert, client_priv_key))
          count += 1
    except:
      print ("  WARNING: No " + nf + " found in NRF!")
  print "Deleted " + str(count) + " suspended NFs"
