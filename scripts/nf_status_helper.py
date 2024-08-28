import os
import sys
import argparse
import requests
import pprint
import json
import textwrap

pp = pprint.PrettyPrinter(indent=4)


def main(input_args):
    args = _parse_args(input_args)
    if args.show_all:
        _show_all_information(args)
    elif args.delete:
        _delete_suspended_nfs(args)
    else:
        _check_nfs_status(args)


def _parse_args(input_args):
    def _is_file(s):
        if not os.path.isfile(s):
            raise argparse.ArgumentTypeError("No such file: {}".format(s))
        return s

    desc = textwrap.dedent('''
The script is used to check provided NF(s) status or their all the information, or delete the suspended Nf(s) from provided NF(s). 
Need to login to nodelocal-api.eccd.local to run the script. For example: 
ssh nodelocal-api.eccd.local
python nf_status_helper.py \\
--client-key /home/eccd/cert/client.key \\
--client-cert /home/eccd/cert/client.crt \\
-H nrf1.n84.5gc.mnc081.mcc240.3gppnetwork.org \\
-P 443 \\
--nf-type AMF SMF PCF AUSF UDR UDM NSSF NEF
(Append -A to show all the information, -D to delete suspended NF(s), --json to print NF(s) status in JSON format)
    ''')
    parser = argparse.ArgumentParser(
        formatter_class=argparse.RawDescriptionHelpFormatter,
        description=desc)
    parser.add_argument(
        "--client-key",
        type=_is_file,
        required=True,
        help="Path of client key file",
    )
    parser.add_argument(
        "--client-cert",
        type=_is_file,
        required=True,
        help="Path of client cert file",
    )
    parser.add_argument(
        "-H",
        "--hostname",
        required=True,
        help="The hostname of NRF server",
    )
    parser.add_argument(
        "-P",
        "--port",
        type=int,
        required=True,
        help="The port of NRF server",
    )
    parser.add_argument(
        "--nf-type",
        dest="nf_types",
        nargs="+",
        required=True,
        choices=['AMF', 'SMF', 'PCF', 'AUSF', 'UDR', 'UDM', 'NSSF', 'NEF'],
        help="The NF(s) to be check for their status"
    )
    parser.add_argument(
        "-A",
        "--show-all",
        default=False,
        action="store_true",
        help="Show all the detailed information for specific NF(s)",
    )
    parser.add_argument(
        "-D",
        "--delete",
        default=False,
        action="store_true",
        help="Delete the suspended NF(s) from the specific NF(s)",
    )
    parser.add_argument(
        "--json",
        default=False,
        action="store_true",
        help="Print the NF(s) status in JSON format",
    )
    return parser.parse_args(input_args)


def _check_nfs_status(args):
    nf_status = {}
    for nf_type in args.nf_types:
        nf_status[nf_type] = {'nfInstanceId': None,
                              'nfStatus': None,
                              'fqdn': None,
                              'nfServices': None}
        url = "https://{hostname}:{port}/nnrf-nfm/v1/nf-instances?nf-type={nf_type}".format(
            hostname=args.hostname,
            port=args.port,
            nf_type=nf_type
        )
        cert = (args.client_cert, args.client_key)
        try:
            resp = requests.get(url, verify=True, cert=cert)
            if resp.json()['_links']['item']:
                for item in resp.json()['_links']['item']:
                    resp = requests.get(item['href'], verify=True, cert=cert)
                    result = resp.json()

                    nf_status[nf_type]['nfInstanceId'] = result.get('nfInstanceId')
                    nf_status[nf_type]['nfStatus'] = result.get('nfStatus')
                    nf_status[nf_type]['fqdn'] = result.get('fqdn')
                    if result.get('nfServices'):
                        nf_status[nf_type]['nfServices'] = {}
                        for nf_service in result.get('nfServices', []):
                            nf_status[nf_type]['nfServices'][nf_service['serviceName']] = {
                                    'nfServiceStatus': nf_service.get('nfServiceStatus')
                            }
        except requests.exceptions.RequestException as ex:
            raise SystemExit(ex)
        except Exception as ex:
            raise SystemExit(ex)
    if args.json:
        pp.pprint(json.dumps(nf_status))
    else:
        pp.pprint(nf_status)


def _show_all_information(args):
    for nf_type in args.nf_types:
        url = "https://{hostname}:{port}/nnrf-nfm/v1/nf-instances?nf-type={nf_type}".format(
            hostname=args.hostname,
            port=args.port,
            nf_type=nf_type
        )
        cert = (args.client_cert, args.client_key)
        print('\n')
        try:
            resp = requests.get(url, verify=True, cert=cert)
            print('*' * 40 + nf_type + '*' * 40)
            print('\n')
            if resp.json()['_links']['item']:
                for item in resp.json()['_links']['item']:
                    resp = requests.get(item['href'], verify=True, cert=cert)
                    if args.json:
                        pp.pprint(json.dumps(resp.json()))
                    else:
                        pp.pprint(resp.json())
                print('\n')
            else:
                print('{} is not found.'.format(nf_type))
        except requests.exceptions.RequestException as ex:
            raise SystemExit(ex)
        except Exception as ex:
            raise SystemExit(ex)
    print('\n')


def _delete_suspended_nfs(args):
    count = 0
    for nf_type in args.nf_types:
        url = "https://{hostname}:{port}/nnrf-nfm/v1/nf-instances?nf-type={nf_type}".format(
            hostname=args.hostname,
            port=args.port,
            nf_type=nf_type)
        cert = (args.client_cert, args.client_key)
        try:
            resp = requests.get(url, verify=True, cert=cert)
            if resp.json()['_links']['item']:
                for item in resp.json()['_links']['item']:
                    resp = requests.get(item['href'], verify=True, cert=cert)
                    resp = resp.json()
                    if resp.get('nfStatus') == 'SUSPENDED':
                        print('Deleting suspended {} with nfInstanceId: {}'.format(
                            nf_type, resp.get('nfInstanceId')))
                        url = "https://{hostname}:{port}/nnrf-nfm/v1/" \
                              "nf-instances/{instance_id}".format(
                               hostname=args.hostname,
                               port=args.port,
                               instance_id=resp.get('nfInstanceId'))
                        requests.delete(url, verify=True, cert=cert)
                        count += 1
        except requests.exceptions.RequestException as ex:
            raise SystemExit(ex)
        except Exception as ex:
            raise SystemExit(ex)
    print('All the {} suspended NFs is deleted.'.format(count))


if __name__ == "__main__":
    try:
        main(sys.argv[1:])
    except Exception as ex:
        raise SystemExit(ex)
