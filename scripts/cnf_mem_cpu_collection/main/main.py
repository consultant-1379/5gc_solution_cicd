"""
    main.py
    Goal:
        utilize other functions created to output pods that used >5% memory and/or CPU compare to previous test(s)
        automate the gathering and comparing process
"""


import argparse
import os
import csv
from data_collection import get_usage
from data_comparison import compare_usage, open_csv
from update_table import update_data
from initialize_table import generate_table
from get_certificate import make_certificate, remove_certificate


def init_setup(fn, content_dict, time, ns, node, _dir):
    try:
        open(fn, "r")
        if os.stat(fn).st_size == 0:
            generate_table(content_dict, time, fn, ns, node, _dir)
        else:
            if "pcg" in open(fn).read():
                add_data_to_csv(fn, ['The cpu collection of eric-pc-up-data-plane is not supported'])
                print("Table successfully initialized")
            else:
                print("Table successfully initialized")
            return True
    except FileNotFoundError:
        generate_table(content_dict, time, fn, ns, node, _dir)
        init_setup(fn, content_dict, time, ns, node, _dir)

def add_data_to_csv(file_path, data):
    with open(file_path, 'a', newline='') as file:
        writer = csv.writer(file)
        writer.writerow(data)

def get_namespace():
    print("Select the NameSpace for memory/CPU data collection and comparison from these options: "
          "\n1. ccdm"
          "\n2. cces"
          "\n3. ccpc"
          "\n4. ccrc"
          "\n5. ccsm"
          "\n6. pcc"
          "\n7. pcg"
          "\n8. all")
    ns = input("Selected NameSpace (i.e \"ccdm\" ): ")
    return ns


def main():
    critpodsfile = "critical_pods.csv"
    threshold = 5

    # define parameters
    # required parameters
    parser = argparse.ArgumentParser()
    # --channel: the test channel/node
    parser.add_argument('--channel', type=str, required=True)
    # --storagepath: the filepath for storing the result file (assume inside /lab/pccc_logs/5GC-CICD/ci/)
    parser.add_argument('--storagepath', type=str, required=True)
    # --starttime: start time of the test in "2023-06-28T10:30:00" format
    parser.add_argument('--starttime', type=str, required=True)
    # --endtime: end time of the time in "2023-06-28T10:30:00" format
    parser.add_argument('--endtime', type=str, required=True)

    # optional parameters
    # --namespace: namespace if not all
    parser.add_argument('--namespace', type=str, required=False)
    # --timeconversion: "Y" if user would like to enter local time
    #                              and have the program convert to UTC
    parser.add_argument('--timeconversion', type=str, required=False)

    args = parser.parse_args()

    # Set default namespace to all
    ns = "all"
    if args.namespace != "":
        ns = args.namespace

    conf = "collect_prom_config.yaml"  # file name of the node/channel configuration

    parent_path = '/lab/pccc_logs/5GC-CICD/ci/'
    result_file = os.path.join(parent_path, f"{args.storagepath}/{ns}_mem_cpu_{args.channel}.csv")

    # make certificate to access data
    # TODO modify data_collection.py to work with new formulas
    make_certificate(args.channel, ns)

    # call get_usage() to obtain and store CPU and memory usage by request
    file, time = get_usage(critpodsfile, conf, args.starttime, args.endtime, ns, args.timeconversion, args.channel)
    print(f"Data successfully collected, see \"{file}\"\n")

    # remove certificate after data collection for safety
    remove_certificate()

    # store critical pods data into variable
    content_dict = open_csv(file)

    # set up result table/file if it doesn't already exist or is empty
    # else proceed to comparing
    if init_setup(result_file, content_dict, time, ns, args.channel, args.storagepath) is True:
        # call compare_usage(filename1, filename2) to compare the memory/CPU usage by request of two test results
        print("\nComparing test results...")
        mem_dict_avg, mem_dict_max, cpu_dict_avg, cpu_dict_max = compare_usage(file, result_file,
                                                                               threshold)
        # collect all info and output to csv
        print("\nUpdating table...")
        update_data(content_dict, mem_dict_avg, mem_dict_max,
                    cpu_dict_avg, cpu_dict_max, time, result_file)
        print(f"Table successfully updated, see \"{result_file}\"")

if __name__ == '__main__':
    main()
