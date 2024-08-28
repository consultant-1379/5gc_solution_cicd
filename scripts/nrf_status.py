#! /usr/bin/python

import json
import requests
import sys

#Configure which type of NF to check status for:
nfs = ["AMF", "SMF", "PCF", "AUSF", "UDR", "UDM", "NSSF", "NEF"]   



if len(sys.argv) > 4 or len(sys.argv) < 3:
  print "Usage to check status: ./nrf_status.py <nrf-ip> <nrf-port>" 
  print "Usage to delete suspended nodes: ./nrf_status.py <nrf-ip> <nrf-port> delete" 
  exit()

ip = sys.argv[1]
port = sys.argv[2]

# Status printout scenario
if len(sys.argv) == 3:
  for nf in nfs:
    try:
      list = requests.get('http://' + ip + ':' + port + '/nnrf-nfm/v1/nf-instances?nf-type=' + nf + '')
      #json_data=list.json()
    except:
      exit ("  ERROR: Unable to reach NRF using IP: " + ip + "!")
    print (nf)
    if list.json()['_links']['item'] == []:
      print ("  WARNING: No " + nf + " found in NRF!")
    else:  
      for x in list.json()['_links']['item']:
        url = x['href']
        result = requests.get(url)
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



# Deleting suspended NFs scenario
elif len(sys.argv) == 4:
  count = 0
  if "delete" == sys.argv[3]:
    for nf in nfs:
      try:
        list = requests.get('http://' + ip + ':' + port + '/nnrf-nfm/v1/nf-instances?nf-type=' + nf + '')
        #json_data=list.json()
      except:
        exit ("  ERROR: Unable to reach NRF using IP: " + ip + "!")
      #print (nf)
      try:  
        for x in list.json()['_links']['item']:
          url = x['href']
          result = requests.get(url)
          #print "  " + result.json()['nfInstanceId']
          #print "  - " + "nfStatus" + " " + result.json()['nfStatus']
          if result.json()['nfStatus'] == "SUSPENDED":
            print "Deleting " + nf + " with ID: " + result.json()['nfInstanceId'] 
            result = requests.delete('http://' + ip + ':' + port + '/nnrf-nfm/v1/nf-instances/' + result.json()['nfInstanceId'] + '')
            count += 1
      except:
        print ("  WARNING: No " + nf + " found in NRF!")
  print "Deleted " + str(count) + " suspended NFs"
	

