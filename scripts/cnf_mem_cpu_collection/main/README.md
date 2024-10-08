
# memory-cpu-comparison

---
## Goal
* Obtain and calculate memory/CPU usage by request (both average and maximum) of given critical pods
* Calculate delta of memory/CPU usage by request between test results
* Find and print pods with delta greater than the threshold (default to 5)
* Organize test results and delta values into a .csv table

---
## Usage
### Prerequisites
**Necessary python packages: pandas and pyyaml**
* if using Python:
  * > pip install pandas
  * > pip install pyyaml
* if using Python3:
  * > pip3 install pandas
  * > pip3 install pyyaml

### Run main.py (4 required parameters & 2 optional parameters), see example:
~~~
if using IDE, edit configuration and add these parameters:
DO NOT include things in the parenthesis when copy/pasting

  --channel
  n89
  --storagepath
  Others
  --starttime
  2023-07-27T9:00:00
  --endtime
  2023-07-27T10:00:00
  --namespace (OPTIONAL: default to all)
  ccdm
  --timeconversion (OPTIONAL: default to no time conversion)
  N
~~~
~~~
if using linux or MacOS: 

  $ python3 main.py --channel n89 --storagepath Others --starttime 2023-07-27T9:00:00 --endtime 2023-07-27T10:00:00 --namespace ccdm --timeconversion N
~~~

### Details about each parameter
#### --channel
* the test channel/node
* ex: n67, n84, ...

#### --storagepath
* the filepath for storing the result file
* assume filepath locates in /lab/pccc_logs/5GC-CICD/ci
* ex: PCVTC-3441_48_hours_Stability_with_1MSAU_1.8MPDU_120Gbps_and_25TPS_background_provisioning_traffic-DM_TM_Ph2_CNIS

#### --starttime & --endtime
* the start and end time for the data gathering
* **IMPORTANT** be sure to enter time in this format:
  ~~~
  YYYY-MM-DDTHH:MM:SS
  example inputs:
  - 2023-06-20T15:30:00
  - 2023-07-05T9:00:00
  ~~~
  *note that it's using 24 hour system, so 1am is 1:00:00 and 1pm is 13:00:00*

#### --namespace
* optional parameter
* default to all
* enter a specific NameSpace if don't want all
* ex: ccdm, pcg, ...

#### --timeconversion
* optional parameter
* assume --starttime & --endtime are in UTC without this parameter
* input "Y" to covert local time to UTC

If all steps are successful,
the program will generate a csv file with all the necessary data
```
the result file will locate in:
lab/pccc_logs/5GC-CICD/ci/{storagepath}/{namespace}_memory_cpu_comparison_{channel}.csv
```
**P.S**: user can open the csv file in Excel/Google Sheets for clearer table display

---
## Details about each module
### main.py
* This script calls the three modules below to automate the process of
  collecting, comparing, and organizing memory/CPU usage by request data
### data_collection.py
* This module is modified based on Quanxin Bao's collect_pm_data/collect_prom.py
* This module collects memory/CPU data of the critical pods and
  calculate the usage by request
### data_comparison.py
* This module compares the results,
  generated by data_collection.py, of the two test cases
### initialize_table.py
* This module creates and initializes the file with end results when running the first test case
### update_table.py
* This module updates the table initialized by initialize_table.py
  with data of the current test case and the delta values compare to the previous test case
  listed in the result file

See comments for more details

---
## Sample Output
~~~
--channel n89 --storagepath Others --starttime 2023-07-28T9:00:00 --endtime 2023-07-28T10:00:00 --namespace ccdm 

Collecting data...
Successfully collected monitoring kube_pod_container_status_ready victoria metrics native format
Successfully collected monitoring kube_pod_container_status_ready json
Successfully collected monitoring container_cpu_usage_seconds_total victoria metrics native format
.
.
.
successfully collected ccdm eric-udr-nudrfe CPUUsageByRequestAvg from monitoring
successfully collected ccdm eric-udr-nudrfe CPUUsageByRequestMax from monitoring
Data successfully collected, see "critPodTable_monitoring.csv"

Table successfully initialized

Comparing test results...

Comparing memory...

Comparing memory...

Comparing CPU...

Comparing CPU...
--------------------------------------------------------------------------
Memory Usage by Request (AVG) with > 5% difference

--------------------------------------------------------------------------
Memory Usage by Request (MAX) with > 5% difference

--------------------------------------------------------------------------
CPU Usage by Request (AVG) with > 5% difference

--------------------------------------------------------------------------
CPU Usage by Request (MAX) with > 5% difference


Updating table...
Table successfully updated, see "/lab/pccc_logs/5GC-CICD/ci/Others/ccdm_mem_cpu_n89.csv"

Process finished with exit code 0
~~~