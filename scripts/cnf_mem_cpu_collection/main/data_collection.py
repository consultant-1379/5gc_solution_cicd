"""
    data_collection.py
    Goal:
        collect and calculate CPU and memory usage by request
        based on the configuration file passed as --config parameter
    Source: modified based on Quanxin Bao's collect_pm_data/collect_prom.py
"""

import os
import subprocess
import yaml
import re
import json
from datetime import datetime


def open_critpods(critpods, ns):
    critPodsList = []
    try:
        FILE = open(critpods)
        # format of each line in critpods file: {namespace}, {pod}
        # thus, split by ", "
        for row in FILE:
            data = row.lower().rstrip().split(", ")
            if ns == "all":
                critPodsList.append(data)
            else:
                if ns == data[0]:
                    critPodsList.append(data)
        return critPodsList
    except FileNotFoundError:
        return False


def open_config(config):
    if not os.path.isfile(config):
        # print(f"File \"{config}\" does not exist, try again ")
        return False
    with open(config, 'r') as f:
        configDict = yaml.safe_load(f)

    return configDict


# get configuration and test name of the test
def get_info():
    config_file = input(f"Enter the filename of the yaml file with the configuration of the test: ")
    test_name = input(f"Name of the test (i.e \"test1\"): ")
    return config_file, test_name

def convert_time(time, difference):
    # TODO handle unreasonable date and month
    if difference[0].__contains__("day"):
        difference_day = difference[0].split(" ")[0]
        difference_hour = difference[0].split(" ")[2]
        day = time.day + int(difference_day)
    else:
        difference_hour = difference[0]
        day = time.day
    difference_minute = difference[1]
    hour = (time.hour + int(difference_hour)) % 24
    minute = (time.minute + int(difference_minute)) % 60
    new_date = datetime.strptime(f"{time.year}-{time.month}-{day}T{hour}:{minute}:{time.second}",
                                 "%Y-%m-%dT%H:%M:%S")
    return new_date


def converted_duration(start_timestr, end_timestr):

    start = datetime.strptime(start_timestr, "%Y-%m-%dT%H:%M:%S")
    end = datetime.strptime(end_timestr, "%Y-%m-%dT%H:%M:%S")

    # format local time
    local_time_tmp = datetime.now()
    local_time = local_time_tmp.replace(microsecond=0)

    # format utc time
    utc_time_tmp = datetime.utcnow()
    utc_time = utc_time_tmp.replace(microsecond=0)

    time_difference = local_time - utc_time
    time_difference_list = str(time_difference).split(":")

    if time_difference_list[0].__contains__("-"):
        time_difference = str(utc_time - local_time).split(":")

    new_start = convert_time(start, time_difference_list)
    new_end = convert_time(end, time_difference_list)

    start_timestamp = str(int(datetime.timestamp(new_start)))
    end_timestamp = str(int(datetime.timestamp(new_end)))
    timerange = str(int(end_timestamp) - int(start_timestamp))

    return start_timestamp, end_timestamp, timerange


def find_duration(start_timestr, end_timestr):

    # format time
    start_timestamp = str(int(datetime.timestamp(datetime.strptime(start_timestr, "%Y-%m-%dT%H:%M:%S"))))
    end_timestamp = str(int(datetime.timestamp(datetime.strptime(end_timestr, "%Y-%m-%dT%H:%M:%S"))))
    timerange = str(int(end_timestamp) - int(start_timestamp))

    return start_timestamp, end_timestamp, timerange

def collectJson(servername, host, metric, api, step, start_timestamp, end_timestamp):
    command = ["curl", "-ks",
               f"https://{host}{api}query_range?query={metric}&start={start_timestamp}&end={end_timestamp}&step={step}"]
    out = subprocess.run(command, stdout=subprocess.PIPE)

    if out.stderr is not None:
        print(f"Error connecting to {servername}")
        print(out.stderr)
        print(" ".join(command))
        return

    try:
        result = out.stdout.decode("utf-8")
        jsoncontent = json.loads(result)

        if len(jsoncontent.get('data', {}).get('result', [])) < 1:
            print(f"Error no metrics in response for {servername} {metric}")
            print(result)
            print(" ".join(command))
            return
        elif len(jsoncontent['data']['result'][0].get('values', [])) < 1:
            print(f"Error no value in response for {servername} {metric}")
            print(result)
            print("".join(command))
            return

        with open(f"pm_metrics/{servername}_{metric}.json", "w") as file:
            file.write(result)

        print(f"Successfully collected {servername} {metric} json")

    except json.JSONDecodeError:
        print(f"JSONDecodeError for {servername} {metric} not json")
        print(out.stdout.decode("utf-8"))


def collectVictoriaNative(servername, host, metric, api, start_timestamp, end_timestamp):
    command = f"curl -ks https://{host}{api}export/native  -d \'match[]={metric}\' -d \"start={start_timestamp}\" -d \"end={end_timestamp}\"  > pm_metrics/{servername}_{metric}.bin"
    process_command = subprocess.Popen(command, stdout=subprocess.PIPE, stderr=subprocess.PIPE, shell=True)
    out, err = process_command.communicate()
    if (err != b'') or (out is None):
        print(f"Error no values in response for {servername} {metric}")
        print(err)
        print(command)
        return
    print(f"Successfully collected {servername} {metric} victoria metrics native format")


def collectSingleValue(host, api, cnfhost, query, namespace, end_timestamp):
    # for below "command" variable:
    # modify "/app/vbuild/RHEL7-x86_64/jq/1.5/bin/" with the absolute path to jq
    # (the absolute path of jq can be found through terminal command "which -a jq" if needed)
    query = query.replace(" ","%20")
    if namespace != 'sc':
        command = f'curl --cert client.crt --key private.key -k \"https://{namespace}-{cnfhost}/api/v1/query?query={query}" |/app/vbuild/RHEL7-x86_64/jq/1.5/bin/jq -r \'.data.result[0].value[1]\' '
    else:
        command = f'curl -k \"https://{host}{api}query?query={query}&time={end_timestamp}" |/app/vbuild/RHEL7-x86_64/jq/1.5/bin/jq -r \'.data.result[0].value[1]\' '
    process_command = subprocess.Popen(command, stdout=subprocess.PIPE, stderr=subprocess.PIPE, shell=True)
    process_command.wait()
    print(command)

    # handle TimeoutExpired
    try:
        out, err = process_command.communicate(timeout=15)
    except subprocess.TimeoutExpired:
        process_command.kill()
        out, err = process_command.communicate()

    if out is None or len(out) == 0:
        print(f"Error no values in response for \n host: {host}\n query: {query}\n")
        print(f"OUT: {out} \nERR: {err} \n")
    return out.decode('ascii')

def replicasQuery(namespace, workload_name, containername, target, end_time, timerange):
    if namespace != 'sc':
        podstring = f'workload_name=~\\"{workload_name}\\",container=~\\"{containername}\\",'
        offsettime = get_offsettime(end_time)
        timestring = f'\[{timerange}s\]'
        # Add pod selector
        targetwithpod = re.sub(r'({)', r'\1' + podstring, target)

        # Remove trailing comma
        targetwithpod = re.sub(r',}', r'\}', targetwithpod)

        # Add timerange to all metrics
        targetwithpodandtime = re.sub(r'(})', r'\1'+ timestring , targetwithpod)

        # Add offsettime
        targetwithpodandtime = re.sub(r'(])', r'\1'+ offsettime , targetwithpodandtime)
    else:
        podstring = f'namespace=\\"{namespace}\\",container=~\\"{containername}\\",pod=~\\"{workload_name}.*\\",'
        timestring = f'\[{timerange}s\]'

        # Add pod and namespace selector
        targetwithpod = re.sub(r'({)', r'\1' + podstring, target)

        # Remove trailing comma
        targetwithpod = re.sub(r',}', r'\}', targetwithpod)

        # Add timerange to all metrics
        if "container_memory_usage" in targetwithpod:
            targetwithpodandtime = re.sub(r'(})', r'\1' + timestring, targetwithpod)
            str1_time = f"\[{timerange}s\]-"
            str2_time = f"\[{timerange}s\])))/"
            str3_time = f")\[{timerange}s\]))/"
            targetwithpodandtime = targetwithpodandtime.replace(str1_time,"-")
            targetwithpodandtime = targetwithpodandtime.replace(str2_time,str3_time)
        else:
            targetwithpodandtime = re.sub(r'(})', r'\1' + timestring, targetwithpod)

    return targetwithpodandtime

def get_offsettime(end_time):
    # get the up-to-date offset time
    local_time_tmp = datetime.now()
    local_time = local_time_tmp.replace(microsecond=0)
    local_time = int(datetime.timestamp(local_time))
    offset_time = str(int(local_time) - int(end_time))
    offset_time = offset_time + "s"
    # format the offset time in curl command
    offsettime = f'%20offset%20{offset_time}'
    return offsettime

def critPodTable(servername, critPodsList, channel_name, server, end_time, timerange):
    columnlist = server["criticalPodsTable"]
    host = server["host"] + "." + channel_name + ".sero.gic.ericsson.se"
    cnfhost = server["cnfhost"] + "." + channel_name + ".sero.gic.ericsson.se"
    api = server["api"]
    critPodTable = "ns, pod"

    for pod in critPodsList:
        namespace = pod[0]

    listpcxx = ["pcc","pcg"]
    listccxx = ["ccrc","ccdm","ccsm","cces","ccpc"]

    if namespace in listpcxx:
        columnlist = server["criticalPodsTable"]["pcxx"]
    elif namespace in listccxx:
        columnlist = server["criticalPodsTable"]["ccxx"]
    elif namespace == 'sc':
        columnlist = server["criticalPodsTable"]["sc"]

    for column in columnlist:
        str1 = column["name"]
        critPodTable += f", {str1}"

    critPodTable += "\n"

    for pod in critPodsList:
        containername = pod[2]
        workload_name = pod[1]
        namespace = pod[0]
        critPodTable += f"{namespace}, {workload_name}"
        for column in columnlist:
            columnName = column["name"]
            try:
                query = replicasQuery(namespace, workload_name, containername, column["target"], end_time, timerange)
                out = collectSingleValue(host, api, cnfhost, query, namespace, end_time)
                if column["unit"] == "float":
                    critPodTable += f", {float(out):.2f}"
                elif column["unit"] == "integer":
                    critPodTable += f", {int(out)}"
                elif column["unit"] == "percent":
                    critPodTable += f", {float(out):.2f} %"
                elif column["unit"] == "gibiByte":
                    critPodTable += f", {(float(out) / 2 ** 30):.2f} GiB"
                print(f"successfully collected {namespace} {workload_name} {columnName} from {servername}")
            except Exception as e:
                critPodTable += f", null"
                print(e)
                print(f"error collecting {namespace}, {workload_name} {column}")

        critPodTable += "\n"

    with open(f"critPodTable_{servername}.csv", "w") as file:
        file.write(critPodTable)


# the "main" function of data_collection
def get_usage(critpods, config, start_time, end_time, ns, conversion, channel):
    pm_metrics_folder = "pm_metrics"
    # create folder if it doesn't already exist for storing (machine-readable) data collected
    if not os.path.isdir(pm_metrics_folder):
        os.mkdir(pm_metrics_folder)

    # open files based on file names given through parameters
    critPodsList = open_critpods(critpods, ns)
    configDict = open_config(config)

    # handle the time period for data collection
    if conversion == "Y":
        st, en, d = converted_duration(start_time, end_time)
    else:
        st, en, d = find_duration(start_time, end_time)  # start time, end time, and duration

    print("\nCollecting data...")  # formatting

    nfvi_list = ['n67', 'n84']
    cnis_list = ['n47', 'n89']
    if channel in nfvi_list:
        channel_name = channel + "-eccd1"
    elif channel in cnis_list:
        channel_name = "node" + channel[1:3]
    else:
        print("Error to get the channel_name(it should be like: n67, n47 ...)")

    # handle victoria and prometheus metrics
    for servername in configDict["servers"]:
        server = configDict["servers"][servername]
        channel_host = server["host"] + "." + channel_name + ".sero.gic.ericsson.se"
        if server["pmtype"] == "victoria-metrics":
            for metric in server.get("metrics", []):
                collectVictoriaNative(servername, channel_host, metric, server["api"], st, en)
                collectJson(servername, channel_host, metric, server["api"], "1h", st, en)
        elif server["pmtype"] == "prometheus":
            for metric in server.get("metrics", []):
                collectJson(servername, channel_host, metric, server["api"], "5m", st, en)
        else:
            print(f"pmtype not recognised")

        if "criticalPodsTable" in server:
            critPodTable(servername, critPodsList, channel_name, server, en, d)

    return f"critPodTable_{servername}.csv", [st, en, d]
