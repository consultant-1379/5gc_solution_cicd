"""
    data_comparison.py
    Goal:
        compare two test results obtained and calculated by data_collection.py
        output those with more than a given threshold
"""

import csv


# get results for previous test
def get_previous_test(result_fn):
    content = {}
    with open(result_fn, 'r') as csvfile:
        csvreader = csv.reader(csvfile)
        # skip first line (header)
        header = next(csvfile).split(",")
        for r in csvreader:
            # finding the location of previous test case's data
            # skip delta values if any
            start_len = 2
            if header[2] == "Delta(AvgMemory)":
                start_len += 4
            keys = [r[1]]
            for k in keys:
                content[k] = r[start_len], r[start_len + 1], r[start_len + 2], r[start_len + 3]
    return content


# open csv file and store content in a dictionary using both NameSpace and Pod as keys for easy access
def open_csv(fn):
    content = {}
    with open(fn, 'r') as csvfile:
        csvreader = csv.reader(csvfile)
        for r in csvreader:
            keys = [r[0], r[1]]
            for k in keys:
                content[k] = r
    return content


# compare the memory usage of each pod
# assume pods of the two csv files are the same
def compare_memory_usage(f1, f2, col):
    mem_dict = {}
    print("\nComparing memory...")
    for k in f1:
        pod = f2[k][1]
        try:
            # extract the float values and calculate the delta(memory usage by request)
            memory_usage_f1 = ((f1[k])[col].split(" "))[1]
            memory_usage_f2 = (f2[pod][col + 2].split(" "))[1]
            memory_usage_difference = "%.2f" % (abs(float(memory_usage_f1) - float(memory_usage_f2)))
            # new dictionary to store both f1 and f2 (memory only, no cpu), along with the newly calculated delta
            mem_dict[pod] = [memory_usage_f1, memory_usage_f2, float(memory_usage_difference)]
        except ValueError:
            if (f1[k])[col] != " null":
                mem_dict[pod] = [((f1[k])[col].split(" "))[1], "null", ((f1[k])[col].split(" "))[1]]
            else:
                if f2[pod][col + 2] != " null":
                    mem_dict[pod] = ["null", (f2[pod][col + 2].split(" "))[1], (f2[pod][col + 2].split(" "))[1]]
                else:
                    mem_dict[pod] = ["null", "null", "null"]
                    print(f"{pod} is null")
    return mem_dict


# compare the cpu usage of each pod
# assume pods of the two csv files are the same
def compare_cpu_usage(f1, f2, col):
    cpu_dict = {}
    print("\nComparing CPU...")
    for k in f1:
        pod = f2[k][1]
        try:
            # extract the float values and calculate the delta(memory usage by request)
            cpu_usage_f1 = ((f1[k])[col].split(" "))[1]
            cpu_usage_f2 = (f2[pod][col + 2].split(" "))[1]
            cpu_usage_difference = "%.2f" % (abs(float(cpu_usage_f1) - float(cpu_usage_f2)))
            # new dictionary to store both f1 and f2 (memory only, no cpu), along with the newly calculated delta
            cpu_dict[pod] = [cpu_usage_f1, cpu_usage_f2, float(cpu_usage_difference)]
        except ValueError:
            if (f1[k])[col] != " null":
                cpu_dict[pod] = [((f1[k])[col].split(" "))[1], "null", ((f1[k])[col].split(" "))[1]]
            else:
                if f2[pod][col + 2] != " null":
                    cpu_dict[pod] = ["null", (f2[pod][col + 2].split(" "))[1], (f2[pod][col + 2].split(" "))[1]]
                else:
                    cpu_dict[pod] = ["null", "null", "null"]
                    print(f"{pod} is null")
    return cpu_dict


# print out the ones that are greater than x% (current set to 5% for testing)
def memory_delta_above_threshold(content, mem_difference, difference, data_type):
    print("--------------------------------------------------------------------------")
    print(f"Memory Usage by Request ({data_type}) with > {difference}% difference\n")
    for p in mem_difference:
        try:
            if mem_difference[p][2] > difference:
                print(f"NameSpace: {content[p][0]}\n"
                      f"Pod: {content[p][1]}\n"
                      f"Test 1 Memory Usage by Request: {mem_difference[p][0]}%\n"
                      f"Test 2 Memory Usage by Request: {mem_difference[p][1]}%\n"
                      f"Delta of Memory Usage by Request: {mem_difference[p][2]}%\n")
        except TypeError:
            pass


# print out the ones that are greater than x% (current set to 5% for testing)
def cpu_delta_above_threshold(content, cpu_difference, difference, data_type):
    print("--------------------------------------------------------------------------")
    print(f"CPU Usage by Request ({data_type}) with > {difference}% difference\n")
    for p in cpu_difference:
        try:
            if cpu_difference[p][2] > difference:
                print(f"NameSpace: {content[p][0]}\n"
                      f"Pod: {content[p][1]}\n"
                      f"Test 1 CPU Usage by Request: {cpu_difference[p][0]}%\n"
                      f"Test 2 CPU Usage by Request: {cpu_difference[p][1]}%\n"
                      f"Delta of CPU Usage by Request: {cpu_difference[p][2]}%\n")
        except TypeError:
            pass


# the "main" function of data_comparison.py
# takes in the filenames of the two test results as parameter
def compare_usage(fn, result_fn, threshold):
    content_f1 = get_previous_test(result_fn)
    content_f2 = open_csv(fn)

    memory_dict_avg = compare_memory_usage(content_f1, content_f2, 0)
    memory_dict_max = compare_memory_usage(content_f1, content_f2, 1)
    cpu_dict_avg = compare_cpu_usage(content_f1, content_f2, 2)
    cpu_dict_max = compare_cpu_usage(content_f1, content_f2, 3)

    memory_delta_above_threshold(content_f2, memory_dict_avg, threshold, "AVG")
    memory_delta_above_threshold(content_f2, memory_dict_max, threshold, "MAX")
    cpu_delta_above_threshold(content_f2, cpu_dict_avg, threshold, "AVG")
    cpu_delta_above_threshold(content_f2, cpu_dict_max, threshold, "MAX")

    return memory_dict_avg, memory_dict_max, cpu_dict_avg, cpu_dict_max
