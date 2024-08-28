#!/usr/bin/env python3

__desc__ = "CCD custom dynamic inventory script for Ansible, in Python3"
__author__ = "Wallance Hou"
__date__ = "02/23/2022"

import os
import sys
import argparse
from subprocess import check_output
import re
import shutil
import configparser

try:
    import json
except ImportError:
    import simplejson as json


def gen_ccd_nodes(role='workers'):
    config = configparser.ConfigParser()
    ibd_inventory = '/mnt/config/inventory/ibd_inventory_file.ini'
    try:
        with open(ibd_inventory) as f:
            config.read_file(f)
    except IOError:
        raise Exception('read ibd inventory file failure, make sure you are on the IBD CCD director node')

    masters = {f"master-{index}":ip for index,ip in enumerate(config['master'].values())}
    directors = {f"director-{index}":ip for index,ip in enumerate(config['director'].values())}

    kube_cmd = "kubectl get node -owide -o=jsonpath='{range .items[*]}{.status.addresses[1].address}" \
               "{\":\"}{.metadata.labels.type}{\":\"}{.status.addresses[].address}{\"\\n\"}{end}'"

    outputs = check_output(kube_cmd, shell=True).decode().splitlines()
    workers = {}
    std_workers = \
        {i.split(':')[0]:i.split(':')[2] for i in outputs if i.split(':')[1] == "standard"}
    ht_workers = \
        {i.split(':')[0]:i.split(':')[2] for i in outputs if i.split(':')[1] == "high-throughput"}

    workers.update(std_workers)
    workers.update(ht_workers)

    return directors, masters, workers, std_workers, ht_workers



class CCDInventory(object):

    def __init__(self):
        self.inventory = {}
        self.args_parser()

        # Called with `--list`.
        if self.args.list:
            self.inventory = self.ccd_inventory()
        # Called with `--host [hostname]`.
        elif self.args.host:
            # Not implemented, since we return _meta info `--list`.
            self.inventory = self.empty_inventory()
        # If no groups or vars are present, return an empty inventory.
        else:
            self.inventory = self.empty_inventory()

        print(json.dumps(self.inventory))

    def ccd_inventory(self):
        hostvars = {}
        directors, masters, workers, std_workers, ht_workers = gen_ccd_nodes()
        director_hostvars = {k:{'ansible_host':v} for k,v in directors.items()}
        master_hostvars = {k:{'ansible_host':v} for k,v in masters.items()}
        workers_hostvars = {k:{'ansible_host':v} for k,v in workers.items()}
        hostvars.update(director_hostvars)
        hostvars.update(master_hostvars)
        hostvars.update(workers_hostvars)

        return {
            'director': {
                'hosts': list(directors.keys())
            },
            'master': {
                'hosts': list(masters.keys())
            },
            'worker': {
                'hosts': list(workers.keys()),
                'vars': {
                    'ansible_python_interpreter': '/usr/bin/python3',
                }
            },
            'std': {
                'hosts': list(std_workers.keys()),
                'vars': {
                    'ansible_python_interpreter': '/usr/bin/python3',
                }
            },
            'ht': {
                'hosts': list(ht_workers.keys()),
                'vars': {
                    'ansible_python_interpreter': '/usr/bin/python3',
                }
            },
            '_meta': {
                'hostvars': hostvars
            }
        }
    # return an empty inventory
    def empty_inventory(self):
        return {'_meta': {'hostvars': {}}}

    # read user input
    def args_parser(self):
        parser = argparse.ArgumentParser()
        parser.add_argument('--list', action = 'store_true')
        parser.add_argument('--host', action = 'store')
        self.args = parser.parse_args()


if __name__ == '__main__':
    CCDInventory()
