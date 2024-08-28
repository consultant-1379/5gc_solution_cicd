#!/usr/bin/env bash
# ----------------------------------------------------------------------------
# Auther: ken.shi@ericsson.com
# ----------------------------------------------------------------------------

VNF_PKGS_PATH="vnfm/onboarding/api/vnfpkgm/v1/vnf_packages"
VNF_INSTANCES_PATH="vnflcm/v1/vnf_instances"
DEFINE_CLUSTER_PATH="vnfm/wfs/api/lcm/v2/cluster"
DEFAULT_USER="vnfm"
DEFAULT_PASS="vnfm"

DEFAULT_INSTANTIATE_FILE="instantiate.json"
DEFAULT_VALUES_FILE="values.yaml"

VNF_INFO_FILE="vnf_info.ini"

VALID_EVNFM_CLUSTERS="^n28-eccd2$|^n99-eccd2$|^n84-eccd2$|^n84-eccd3$|^pod56-eccd2$"

help()
{
    echo "Description:"
    echo "This script helps to do VNF deployment (onboarding, instantiation and termination) using EVNFM."
    echo "Typical usage: (run the script on the SERO terminal servers)"
    echo "easy-evnfm-cli.sh -c evnfm_cluster -o CSAR_file_or_folder"
    echo "                  -c evnfm_cluster -i vnf_name [-s instantiate_file -v values_file]"
    echo "                  -c evnfm_cluster -t vnf_name"
    echo "                  -c evnfm_cluster -d"
    echo "                  -c evnfm_cluster -r traffic_cluster"
    echo "-o CSAR_file_or_folder   Single CSAR file, or folder which contains CSAR files"
    echo "-i vnf_name              Instantiate a VNF with name vnf-name"
    echo "-s instantiate_file      Optional, json type file, default is instantiate.json in current directory"
    echo "-v values_file           Optional, yaml type file, default is values.yaml in current directory"
    echo "-t vnf_name              Terminate a VNF with name vnf-name"
    echo "-d                       Delete VNF package interactively"
    echo "-r traffic_cluster       Define/Register addition cluster to EVNFM, eg. n28-eccd3, n99-eccd1"
    echo "-c evnfm_cluster         The EVNFM cluster name, eg. n28-eccd2, n99-eccd2, and etc."
    echo "-n evnfm_address         The EVNFM ingress host FQDN, eg. evnfm.ingress.n28-eccd2.sero.gic.ericsson.se"    
    echo "-u evnfm_user            Optional. Default is vnfm"
    echo "-p evnfm_password        Optional. Default is vnfm"
    echo "Note: At most one of '-o', '-i' '-t', '-d' and '-r' can be provided."
    echo "      If none of them is provided, print existing package and VNF information"
    echo "      either '-c' or '-n' is needed. If running on EVNFM Cluster, neither is needed."
    echo "Examples:"
    echo "Onboard a VNF package on N28 EVNFM:"
    echo "    easy-evnfm-cli.sh -c n28-eccd2 -o <path>/PCC_CXP9037447_1-R37B225.csar"
    echo "Delete a VNF package on N28 EVNFM:"
    echo "    easy-evnfm-cli.sh -c n28-eccd2 -d"
    echo "Instantiate N28 eccd1 PCC, navigate to the folder 5gc_sa_pkg/lab/n28/eccd1/pcc"
    echo "    easy-evnfm-cli.sh -c n28-eccd2 -i n28-pcc1"
    echo "Terminate N28 eccd1 PCC:"
    echo "    easy-evnfm-cli.sh -c n28-eccd2 -t n28-pcc1"
    echo "Define N28 eccd3 in N28 EVNFM:"
    echo "    easy-evnfm-cli.sh -c n28-eccd2 -r n28-eccd3"
    exit 1
}

get_token()
{
    host=$1
    user=$2
    pass=$3

    curl -k -sS -X POST https://${host}/auth/v1 \
        -H "Content-Type: application/json" \
        -H "X-login: ${user}" \
        -H "X-password: ${pass}"
}

get_all_packages()
{
    host=$1
    token=$2

    curl -k -sS -X GET https://${host}/${VNF_PKGS_PATH} \
        -H 'Accept: application/json' \
        -H "cookie: JSESSIONID=${token}" \
        | jq 'map(del (.softwareImages))' \
        | jq 'sort_by(.vnfSoftwareVersion)' \
        | jq 'sort_by(.vnfProductName)'
}

get_all_instances()
{
    host=$1
    token=$2

    curl -k -sS -X GET https://${host}/${VNF_INSTANCES_PATH} \
        -H 'Accept: application/json' \
        -H "cookie: JSESSIONID=${token}" \
        | jq 'map(del (.instantiatedVnfInfo))' \
        | jq 'sort_by(.vnfSoftwareVersion)' \
        | jq 'sort_by(.vnfProductName)'
}

get_all_operations()
{
    host=$1
    token=$2

    curl -k -sS -X GET https://${host}/vnflcm/v1/vnf_lcm_op_occs \
        -H 'Accept: application/json' \
        -H "cookie: JSESSIONID=${token}" 
}

create_package_id()
{
    host=$1
    token=$2

    curl -k -sS -X POST https://${host}/${VNF_PKGS_PATH}  \
        -H 'Content-Type: application/json' \
        -H 'Accept: application/json' \
        -H "cookie:JSESSIONID=${token}" \
        -d '{
                "userDefinedData":
                {
                    "description": "testing CreateVnfPkgInfoRequest"
                }
            }' \
        | jq -r '.id'
}

onboard_package()
{
    host=$1
    token=$2
    file=$3
    vnfPkgId=$4

    curl -k -sS -X PUT https://${host}/${VNF_PKGS_PATH}/${vnfPkgId}/package_content \
        -H 'Accept: */*' \
        -H 'Content-Type: multipart/form-data' \
        -H "cookie:JSESSIONID=${token}" \
        -F file=@${file} 2>&1
}

get_package()
{
    host=$1
    token=$2
    vnfPkgId=$3

    curl -k -sS -X GET https://${host}/${VNF_PKGS_PATH}/${vnfPkgId} \
        -H 'Accept: application/json' \
        -H "cookie: JSESSIONID=${token}"
}

delete_package()
{
    host=$1
    token=$2
    vnfPkgId=$3

    curl -k -sS -X DELETE https://${host}/${VNF_PKGS_PATH}/${vnfPkgId} \
        -H 'Accept: application/json' \
        -H "cookie: JSESSIONID=${token}"
}

get_instance()
{
    host=$1
    token=$2
    vnfInstanceId=$3

    curl -k -sS -X GET https://${host}/${VNF_INSTANCES_PATH}/${vnfInstanceId} \
            -H 'Accept: application/json' \
            -H "cookie: JSESSIONID=${token}"
}

create_instance_id()
{
    host=$1
    token=$2
    vnfdId=$3
    name=$4

    curl -k -sS -X POST https://${host}/${VNF_INSTANCES_PATH} \
        -H 'Accept: application/json' \
        -H 'Content-Type: application/json' \
        -H "cookie:JSESSIONID=${token}" \
        -d '{
                "vnfdId": "'${vnfdId}'",
                "vnfInstanceName": "'${name}'"
            }' \
        | jq -r .id
}

delete_instance_id()
{
    host=$1
    token=$2
    vnfInstanceId=$3

    curl -k -sS -X DELETE https://${host}/${VNF_INSTANCES_PATH}/${vnfInstanceId} \
        -H 'Accept: application/json' \
        -H "cookie:JSESSIONID=${token}"
}

instantiate()
{
    host=$1
    token=$2
    instance_id=$3
    instantiate_file=$4
    values_file=$5

    curl -k -sS -X POST https://${host}/${VNF_INSTANCES_PATH}/${instance_id}/instantiate \
        -H 'Content-Type: multipart/form-data' \
        -H "cookie:JSESSIONID=${token}" \
        -F instantiateVnfRequest=@${instantiate_file} \
        -F valuesFile=@${values_file}
}

terminate()
{
    host=$1
    token=$2
    vnfInstanceId=$3

    curl -k -sS -X POST https://${host}/${VNF_INSTANCES_PATH}/${vnfInstanceId}/terminate \
        -H 'Content-Type: application/json' \
        -H 'cookie:JSESSIONID='${token} \
        -d '{
                "terminationType": "FORCEFUL",
                "additionalParams":
                {
                    "skipVerification":true,
                    "cleanUpResources":true,
                    "applicationTimeOut": "1200",
                    "commandTimeout": "1000",
                    "pvcTimeOut": "1000"
                }
            }'
}

define_cluster()
{
    host=$1
    token=$2
    config_file=$3

    curl -k -i -sS -X POST https://${host}/${DEFINE_CLUSTER_PATH} \
        -H "cookie:JSESSIONID=${token}" \
        -F clusterConfig=@${config_file}
}

onboard_csar_file()
{
    host=$1
    token=$2
    file=$3
    vnfPkgId=$4

    echo "$(date +"%Y-%m-%d %H:%M:%S") INFO: The vnfPkgId is ${vnfPkgId}"
    start_time=$(date +%s)
    echo "$(date +"%Y-%m-%d %H:%M:%S") INFO: Start onboarding VNF package ${file}"
    onboard_package ${host} ${token} ${file} ${vnfPkgId}

    echo "$(date +"%Y-%m-%d %H:%M:%S") INFO: Checking the onboarding state"
    while true
    do
        waiting 10
        onboarding_status=$(get_package ${host} ${token} ${vnfPkgId} | jq -r .onboardingState)
        if [[ ${onboarding_status} == "ONBOARDED" ]]; then
            echo "$(date +"%Y-%m-%d %H:%M:%S") INFO: onboardingState is now ONBOARDED."
            break
        fi
        echo "$(date +"%Y-%m-%d %H:%M:%S") INFO: Oboarding state is ${onboarding_status}"
    done
    echo "$(date +"%Y-%m-%d %H:%M:%S") INFO: Checking the operational state."
    while true
    do
        operational_status=$(get_package ${host} ${token} ${vnfPkgId} | jq -r .operationalState)
        if [[ ${operational_status} == "ENABLED" ]]; then
            echo "$(date +"%Y-%m-%d %H:%M:%S") INFO: operationalState is now ENABLED."
            break
        fi
        echo "$(date +"%Y-%m-%d %H:%M:%S") INFO: Operational state is ${operational_status}"
        waiting 10
    done
    finish_time=$(date +%s)
    duration=$((${finish_time} - ${start_time}))
    dura_min=$((${duration} / 60))
    dura_sec=$((${duration} % 60))
    echo "$(date +"%Y-%m-%d %H:%M:%S") INFO: The VNF package ${file} is successfully onboarded! Duration: ${dura_min}m${dura_sec}s"
}

print_package_info()
{
    package_info=$1

    vnfProductName=$(echo ${package_info} | jq -r .vnfProductName)
    vnfSoftwareVersion=$(echo ${package_info} | jq -r .vnfSoftwareVersion)
    vnfdVersion=$(echo ${package_info} | jq -r .vnfdVersion)
    onboardingState=$(echo ${package_info} | jq -r .onboardingState)
    operationalState=$(echo ${package_info} | jq -r .operationalState)
    usageState=$(echo ${package_info} | jq -r .usageState)
    #vnfdId=$(echo ${package_info} | jq -r .vnfdId | cut -d'-' -f1)
    vnfdId=$(echo ${package_info} | jq -r .vnfdId)

    echo -n "${vnfProductName} "
    echo -n "${vnfSoftwareVersion} "
    echo -n "${vnfdVersion} "
    echo -n "${onboardingState} "
    echo -n "${operationalState} "
    echo -n "${usageState} "
    echo "${vnfdId}"
}

print_instance_info()
{
    instance_info=$1
    operation_info=$2

    vnfInstanceName=$(echo ${instance_info} | jq -r .vnfInstanceName)
    vnfProductName=$(echo ${instance_info} | jq -r .vnfProductName)
    vnfSoftwareVersion=$(echo ${instance_info} | jq -r .vnfSoftwareVersion)
    vnfdVersion=$(echo ${instance_info} | jq -r .vnfdVersion)
    instantiationState=$(echo ${instance_info} | jq -r .instantiationState)
    clusterName=$(echo ${instance_info} | jq -r .clusterName)
    vnfdId=$(echo ${instance_info} | jq -r .vnfdId | cut -d'-' -f1)
    operationState=$(echo ${operation_info} | jq -s -r 'sort_by(.startTime) | reverse | .[0].operationState')
    startTime=$(echo ${operation_info} | jq -s -r 'sort_by(.startTime) | reverse | .[0].startTime' | cut -d'.' -f1)

    echo -n "${vnfInstanceName} "
    echo -n "${vnfProductName} "
    echo -n "${vnfSoftwareVersion} "
    echo -n "${vnfdVersion} "
    echo -n "${instantiationState} "
    echo -n "${clusterName} "
    echo -n "${vnfdId} "
    echo -n "${operationState} "
    echo "${startTime}"
}

print_all_packages_info()
{
    packages_info=$1

    package_ids=$(echo ${packages_info} | jq -r .[].id)
    echo "Index vnfProductName vnfSoftwareVersion vnfdVersion onboardingState operationalState usageState vnfdId"
    i=1
    for id in ${package_ids}; do
        package_info=$(echo ${packages_info} | jq --arg id "$id" '.[] | select(.id == $id)')
        echo -n "${i}) "
        print_package_info "${package_info}"
        i=$((i+1))
    done
}

print_all_instances_info()
{
    instances_info=$1
    operations_info=$2

    instances_ids=$(echo ${instances_info} | jq -r .[].id)
    echo "Index vnfInstanceName vnfProductName vnfSoftwareVersion vnfdVersion instantiationState clusterName vnfdId operationState startTime"
    i=1
    for id in ${instances_ids}; do
        instance_info=$(echo ${instances_info} | jq --arg id "$id" '.[] | select(.id == $id)')
        operation_info=$(echo ${operations_info} | jq --arg id "$id" '.[] | select(.vnfInstanceId == $id)')
        echo -n "${i}) "
        print_instance_info "${instance_info}" "${operation_info}"
        i=$((i+1))
    done
}

waiting()
{
    for ((i=${1}; i>=0; i--)); do
    echo -ne "$(date +"%Y-%m-%d %H:%M:%S") INFO: Before continuing, please wait seconds: $i     \r"
    sleep 1
    done
    echo
}

change_password()
{
    ip=$1
    user=$2
    old_pass=$3
    new_pass=$4

/usr/bin/expect << EOD
spawn ssh -q -o StrictHostKeyChecking=no ${user}@${ip}
expect "Password: "
send "${old_pass}\n"
expect "Password: "
send "${old_pass}\n"
expect "Password: "
send "${new_pass}\n"
expect "Password: "
send "${new_pass}\n"
expect "#"
EOD
}

script_folder="$(dirname $(readlink -f "$0"))"
kubeconfig_folder="${script_folder}/kubeconfig"

# parse input arguments
while getopts 'c:n:u:p:o:i:s:v:t:dr:h' OPT; do
    case $OPT in
        c) evnfm_cluster="$OPTARG";;
        n) evnfm_address="$OPTARG";;
        u) evnfm_user="$OPTARG";;
        p) evnfm_pass="$OPTARG";;
        o) file_or_folder="$OPTARG";;
        i) vnf_name="$OPTARG";;
        s) instantiate_file="$OPTARG";;
        v) values_file="$OPTARG";;
        t) terminate_vnf="$OPTARG";;
        d) is_delete_package=1;;
        r) traffic_cluster="$OPTARG";;
        h) help;;
        ?) help;;
    esac
done

if [[ -z ${evnfm_user} ]]; then
    evnfm_user=${DEFAULT_USER}
fi
if [[ -z ${evnfm_pass} ]]; then
    evnfm_pass=${DEFAULT_PASS}
fi

if [[ -z ${evnfm_cluster} ]] && [[ -z ${evnfm_address} ]]; then
    ingress_host=$(kubectl -n evnfm get ingress eric-eo-evnfm-nbi -o jsonpath='{.spec.rules[0].host}')
    if [[ -z ${ingress_host} ]]; then
        echo "$(date +"%Y-%m-%d %H:%M:%S") WARNING: You are probably not on the EVNFM cluster."
        echo "$(date +"%Y-%m-%d %H:%M:%S") WARNING: Please specify target EVNFM cluster using '-c', eg. -c n28-eccd2"
        echo "$(date +"%Y-%m-%d %H:%M:%S") WARNING: Or specify the EVNFM address using '-n', eg. -n evnfm.ingress.n28-eccd2.sero.gic.ericsson.se"
        help
    fi
elif [[ -n ${evnfm_cluster} ]]; then
    if [[ "${evnfm_cluster}" == "$(echo ${evnfm_cluster} | egrep ${VALID_EVNFM_CLUSTERS})" ]]; then 
        if [[ "${evnfm_cluster}" == "pod56-eccd2" ]]; then
            ingress_host="evnfm.ingress.${evnfm_cluster}.seln.ete.ericsson.se"
        else
            ingress_host="evnfm.ingress.${evnfm_cluster}.sero.gic.ericsson.se"
        fi
    else
        echo "$(date +"%Y-%m-%d %H:%M:%S") ERROR: Invalid EVNFM cluster, exit"
        exit 1
    fi
elif [[ -n ${evnfm_address} ]]; then
    ingress_host=${evnfm_address}
fi
echo "$(date +"%Y-%m-%d %H:%M:%S") INFO: EVNFM Ingress Host: ${ingress_host}"

if [[ -z ${instantiate_file} ]]; then
    instantiate_file=${DEFAULT_INSTANTIATE_FILE}
fi
if [[ -z ${values_file} ]]; then
    values_file=${DEFAULT_VALUES_FILE}
fi

# Get token
jsession_id=$(get_token ${ingress_host} ${evnfm_user} ${evnfm_pass})
echo "$(date +"%Y-%m-%d %H:%M:%S") INFO: Generated JSESSION_ID: ${jsession_id}"

packages_info=$(get_all_packages ${ingress_host} ${jsession_id}) 
instances_info=$(get_all_instances ${ingress_host} ${jsession_id})
operations_info=$(get_all_operations ${ingress_host} ${jsession_id})

###########################################################
# Print VNF LCM information                               #
###########################################################
if [[ -z ${file_or_folder} ]] && [[ -z ${vnf_name} ]] && [[ -z ${terminate_vnf} ]] && [[ -z ${is_delete_package} ]] && [[ -z ${traffic_cluster} ]]; then
    echo
    echo "$(date +"%Y-%m-%d %H:%M:%S") INFO: List current VNF packages information:"
    print_all_packages_info "${packages_info}" | column -t
    echo
    echo "$(date +"%Y-%m-%d %H:%M:%S") INFO: List current VNF instances information:"
    print_all_instances_info "${instances_info}" "${operations_info}" | column -t
    echo


###########################################################
# Onboad package(s)                                       #
###########################################################
elif [[ ! -z ${file_or_folder} ]] && [[ -z ${vnf_name} ]] && [[ -z ${terminate_vnf} ]] && [[ -z ${is_delete_package} ]] && [[ -z ${traffic_cluster} ]]; then

    ongoing_onboarding=$(echo ${packages_info} | jq -r .[].onboardingState | egrep 'UPLOADING|PROCESSING')
    if [[ -z ${ongoing_onboarding} ]]; then
        echo "$(date +"%Y-%m-%d %H:%M:%S") INFO: There is no ongoing onboarding activity."
    else
        echo "$(date +"%Y-%m-%d %H:%M:%S") WARNING: There is ongoing onboarding activity. Exit!"
        exit 1
    fi

    if [[ -f ${file_or_folder} ]]; then
        csar_file=${file_or_folder}
        if [[ "${csar_file##*.}" != "csar" ]]; then
            echo "$(date +"%Y-%m-%d %H:%M:%S") ERROR: ${csar_file} seems not a CSAR package. Exit!"
            exit 1
        fi
        echo "$(date +"%Y-%m-%d %H:%M:%S") INFO: ${csar_file} file is to be onboarded."
        package_id=$(create_package_id ${ingress_host} ${jsession_id})
        onboard_csar_file ${ingress_host} ${jsession_id} ${csar_file} ${package_id}
    elif [[ -d ${file_or_folder} ]]; then
        dir=${file_or_folder}
        csar_file_list=$(ls -1 ${dir} | grep "\.csar$")
        if [[ -z ${csar_file_list} ]]; then
            echo "$(date +"%Y-%m-%d %H:%M:%S") ERROR: There is no CSAR file in ${dir}."
            exit 1
        fi
        echo "$(date +"%Y-%m-%d %H:%M:%S") INFO: The following files are to be onboarded:"
        echo "---------------------------------------------"
        echo "${csar_file_list}"
        echo "---------------------------------------------"
        for csar_file in ${csar_file_list}; do
            package_id=$(create_package_id ${ingress_host} ${jsession_id})
            onboard_csar_file ${ingress_host} ${jsession_id} "${dir}/${csar_file}" ${package_id}
        done
    else
        echo "Error: Invalid CSAR file or directory: ${file_or_folder}"
        exit 1
    fi

###########################################################
# Instantiate a VNF                                       #
###########################################################
elif [[ -z ${file_or_folder} ]] && [[ ! -z ${vnf_name} ]] && [[ -z ${terminate_vnf} ]] && [[ -z ${is_delete_package} ]]; then
    
    if [[ ! -f ${instantiate_file} ]] || [[ ! -f ${values_file} ]]; then
        echo "$(date +"%Y-%m-%d %H:%M:%S") ERROR: ${instantiate_file} or ${values_file} doesn't exist."
        help
    fi

    # Check existing instance with the same name
    existing_instances=$(echo ${instances_info} | jq -r --arg vnfInstanceName ${vnf_name} '.[] | select(.vnfInstanceName == $vnfInstanceName)' | jq -s .)
    if [[ "${existing_instances}" != "[]" ]]; then
        echo "$(date +"%Y-%m-%d %H:%M:%S") ERROR: Duplicate instance name. There is already an instance named with ${vnf_name}. Exit"
        exit 1
    fi

    # Source vnf_info.ini if exists
    if [[ -f ${VNF_INFO_FILE} ]]; then
        source ${VNF_INFO_FILE}
        if [[ -z ${vnfdId} && ! -z ${vnfProductName} && ! -z ${vnfSoftwareVersion} ]]; then
            packages_info=$(echo ${packages_info} | jq -r \
                --arg vnfProductName ${vnfProductName} --arg vnfSoftwareVersion ${vnfSoftwareVersion} \
                '.[] | select(.vnfProductName == $vnfProductName and .vnfSoftwareVersion == $vnfSoftwareVersion)' \
                | jq -s .)
        fi
    else
        echo "$(date +"%Y-%m-%d %H:%M:%S") WARNING: file ${VNF_INFO_FILE} doesn't exist."
    fi
 
    # Get the vnfdId if it doesn't exist in vnf_info.ini
    if [[ -z ${vnfdId} ]]; then
        num_packages=$(echo ${packages_info} | jq -r .[].id | wc -l)
        if [[ ${num_packages} -eq 0 ]]; then
            echo "No package available for ${vnf_name}. Exit"
            exit 1
        elif [[ ${num_packages} -eq 1 ]]; then
            vnfdId=$(echo ${packages_info} | jq -r .[].vnfdId)
        else
            echo
            print_all_packages_info "${packages_info}" | column -t
            echo
            while true; do
                read -p "Select the VNF package list index (0,1,2..n): " input_id
                if [[ "${input_id}" =~ ^[0-9]+$ ]] && [[ ${input_id} -gt 0 ]] && [[ ${input_id} -le ${num_packages} ]]; then
                    vnfdId=$(echo ${packages_info} | jq -r .[$((${input_id}-1))].vnfdId)
                    break
                else
                    echo "$(date +"%Y-%m-%d %H:%M:%S") ERROR: Invalid input. Please try again!"
                fi
            done
        fi
    fi 

    clusterName=$(jq -r .clusterName ${instantiate_file})
    namespace=$(jq -r .additionalParams.namespace ${instantiate_file})
    kubeconfig_file="${kubeconfig_folder}/${clusterName}.config"
    if [[ -f ${kubeconfig_file} ]]; then
        echo "$(date +"%Y-%m-%d %H:%M:%S") INFO: Kubeconfig file: ${kubeconfig_file} exsits"
    else
        echo "$(date +"%Y-%m-%d %H:%M:%S") ERROR: Kubeconfig file: ${kubeconfig_file} doesn't exsit. Exit"
        exit 1
    fi

    # Create namespace
    echo "$(date +"%Y-%m-%d %H:%M:%S") INFO: Create namespace ${namespace} on cluster ${clusterName}"
    kubectl --kubeconfig=${kubeconfig_file} create ns ${namespace}
    if [[ $? -ne 0 ]]; then
        echo "$(date +"%Y-%m-%d %H:%M:%S") ERROR: Failed to create namespace ${namespace} on cluster ${clusterName}. Exit"
        exit 1
    fi

    # Create snmp config, not for PCG
    if [[ -f ${snmp_config_file} && ${vnfProductName} != "PCG" ]]; then
        echo "$(date +"%Y-%m-%d %H:%M:%S") INFO: Create secret snmp-alarm-provider-config in namespace ${namespace}"
        kubectl --kubeconfig=${kubeconfig_file} -n ${namespace} create secret generic snmp-alarm-provider-config --from-file=${snmp_config_file}
    fi

    # ---- EVNFM LCM start ----
    # Start the instantiation
    instance_id=$(create_instance_id ${ingress_host} ${jsession_id} ${vnfdId} ${vnf_name})
    echo "$(date +"%Y-%m-%d %H:%M:%S") INFO: Created instance ID ${instance_id}"
    echo "$(date +"%Y-%m-%d %H:%M:%S") INFO: Instantiating the VNF ${vnf_name} on cluster ${clusterName}"
    instantiate ${ingress_host} ${jsession_id} ${instance_id} ${instantiate_file} ${values_file}

    # Checking instantiation status
    while true; do
        instance_info=$(get_instance ${ingress_host} ${jsession_id} ${instance_id})
        instantiationState=$(echo ${instance_info} | jq -r .instantiationState)
        operations_info=$(get_all_operations ${ingress_host} ${jsession_id})
        operation_info=$(echo ${operations_info} | jq --arg id "${instance_id}" '.[] | select(.vnfInstanceId == $id)')
        #operationState=$(echo ${operation_info} | jq -r '. | select(.operation == "INSTANTIATE") | .operationState')
        operationState=$(echo ${operation_info} | jq -s -r 'sort_by(.startTime) | reverse | .[0].operationState')

        echo "$(date +"%Y-%m-%d %H:%M:%S") INFO: ${vnf_name} instantiationState is ${instantiationState}, and the operationState is ${operationState}"
        if [[ "${instantiationState}" == "INSTANTIATED" && "${operationState}" == "COMPLETED" ]]; then
            echo "$(date +"%Y-%m-%d %H:%M:%S") INFO: The VNF ${vnf_name} is instantiated successfully!"
            break
        elif [[ "${operationState}" == "FAILED" ]]; then
            #echo ${operation_info} | jq -r '. | select(.operation == "INSTANTIATE") | .error'
            echo ${operation_info} | jq -s -r 'sort_by(.startTime) | reverse | .[0].error'
            exit 1
        fi
        waiting 10
    done
    # ---- EVNFM LCM end ----

    # Checking pod status(skip search engine curator)
    echo "$(date +"%Y-%m-%d %H:%M:%S") INFO: Waiting for all Pods in Running status"
    while true; do
        not_running=$(kubectl --kubeconfig=${kubeconfig_file} -n ${namespace} get pod \
            | egrep -v 'NAME|Running|Completed|eric-data-search-engine-curator' | wc -l)
        if [[ ${not_running} -eq 0 ]]; then
            echo "$(date +"%Y-%m-%d %H:%M:%S") INFO: All Pods are in Running status (ignoring search engine curator)"
            break
        else
            echo "$(date +"%Y-%m-%d %H:%M:%S") INFO: ${not_running} Pods are not in Running status (ignoring search engine curator)"
        fi
        waiting 5
    done

    # Post configurations
    # Only for PCG, patch log shipper and re-create snmp secret
    if [[ -f ${snmp_config_file} && ${vnfProductName} == "PCG" ]]; then
        echo "$(date +"%Y-%m-%d %H:%M:%S") INFO: Patch daemonset eric-log-shipper for PCG"
        log_shipper_patch_json='{ "spec": { "template": { "spec": { "tolerations": [ { "effect": "NoSchedule", "key": "high-throughput", "operator": "Equal", "value": "true" } ] } } } }'
        kubectl --kubeconfig=${kubeconfig_file} -n ${namespace} patch daemonsets eric-log-shipper -p "${log_shipper_patch_json}"
        echo "$(date +"%Y-%m-%d %H:%M:%S") INFO: Re-create secret snmp-alarm-provider-config PCG"
        kubectl --kubeconfig=${kubeconfig_file} -n ${namespace} delete secret snmp-alarm-provider-config
        kubectl --kubeconfig=${kubeconfig_file} -n ${namespace} create secret generic snmp-alarm-provider-config --from-file=${snmp_config_file}
        kubectl --kubeconfig=${kubeconfig_file} -n ${namespace} delete pod -l app.kubernetes.io/name=eric-fh-snmp-alarm-provider
    fi

    # For PCC and PCG to load the configurations
    if [[ ${vnfProductName} == "PCC" || ${vnfProductName} == "PCG" ]] && [[ -n ${OAM_IP} && -n ${day0_user} && -n ${day0_pass} ]]; then

        echo "$(date +"%Y-%m-%d %H:%M:%S") INFO: Perform the post configurations for ${vnf_name}"
        echo "$(date +"%Y-%m-%d %H:%M:%S") INFO: Create day1 user, change password and load CM YANG configurations"

        echo "$(date +"%Y-%m-%d %H:%M:%S") INFO: Remove existing SSH host key"
        ssh-keygen -R ${OAM_IP} > /dev/null 2>&1

        # Configure day1 user
        echo "$(date +"%Y-%m-%d %H:%M:%S") INFO: Create day1 user by loading: ${day1_user_config_file}"
        while true; do
            result=$(sshpass -p ${day0_pass} ssh ${day0_user}@${OAM_IP} -q -o StrictHostKeyChecking=no < ${day1_user_config_file} 2>/dev/null)
            if [[ ${result} == "Commit complete." ]]; then
                echo "$(date +"%Y-%m-%d %H:%M:%S") INFO: Created day1 user"
                break
            else
                echo "${result}"
                echo "$(date +"%Y-%m-%d %H:%M:%S") ERROR: Failed to create day1 user, will try again"
            fi
            waiting 10
        done
        
        #waiting 15
        # Change day1 password
        while true; do
            echo "$(date +"%Y-%m-%d %H:%M:%S") INFO: Change the password for day1 user: ${day1_user}"
            result=$(change_password ${OAM_IP} ${day1_user} ${day1_pass_init} ${day1_pass} 2>/dev/null)
            prompt_success=$(echo "${result}" | tail -1 | grep "#$")
            if [[ -n ${prompt_success} ]]; then
                echo "$(date +"%Y-%m-%d %H:%M:%S") INFO: Changed password successfully"
                break
            else
                echo "${result}"
                echo "$(date +"%Y-%m-%d %H:%M:%S") ERROR: Failed to change the password, will try again"
            fi
        done
 
        # Load post configurations 
        for config_file in ${day1_configurations[@]}; do
            echo "$(date +"%Y-%m-%d %H:%M:%S") INFO: Load configuration: ${config_file}"
            while true; do
                result=$(sshpass -p ${day1_pass} ssh ${day1_user}@${OAM_IP} -q -o StrictHostKeyChecking=no < ${config_file} 2>/dev/null)
                if [[ ${result} == "Commit complete." ]]; then
                    echo "$(date +"%Y-%m-%d %H:%M:%S") INFO: Loaded ${config_file} successfully"
                    break
                else
                    echo "${result}"
                    echo "$(date +"%Y-%m-%d %H:%M:%S") ERROR: Failed to load configuration ${config_file}, will try again"
                fi
                waiting 10
            done
            waiting 10
        done
        echo "$(date +"%Y-%m-%d %H:%M:%S") INFO: Finished post configurations"
    else
        echo "$(date +"%Y-%m-%d %H:%M:%S") WARNING: Missing information in ${VNF_INFO_FILE}, can't apply post config"
    fi


###########################################################
# Terminate a VNF                                         #
###########################################################
elif [[ -z ${file_or_folder} ]] && [[ -z ${vnf_name} ]] && [[ ! -z ${terminate_vnf} ]] && [[ -z ${is_delete_package} ]] && [[ -z ${traffic_cluster} ]]; then
    instances_info=$(echo ${instances_info} | jq -r --arg vnfInstanceName ${terminate_vnf} '.[] | select(.vnfInstanceName == $vnfInstanceName)' | jq -s .)
    if [[ "${instances_info}" == "[]" ]]; then
        echo "$(date +"%Y-%m-%d %H:%M:%S") ERROR: There is no instance named with ${terminate_vnf}"
        exit 1
    fi

    # Find out how many instances with the same name that is to be terminated
    num_instances=$(echo ${instances_info} | jq -r .[].id | wc -l)
    if [[ ${num_instances} -gt 1 ]]; then
        echo
        print_all_instances_info "${instances_info}" "${operations_info}" | column -t
        echo
        echo "$(date +"%Y-%m-%d %H:%M:%S") WARNING: There are multiple instances with the name ${terminate_vnf}"
        while true; do
            read -p "Select the VNF instance list index (0,1,2..n): " input_id
            if [[ "${input_id}" =~ ^[0-9]+$ ]] && [[ ${input_id} -gt 0 ]] && [[ ${input_id} -le ${num_instances} ]]; then
                instance_id=$(echo ${instances_info} | jq -r .[$((${input_id}-1))].id)
                break
            else
                echo "$(date +"%Y-%m-%d %H:%M:%S") ERROR: Invalid input. Please try again!"
            fi
        done
    else
        instance_id=$(echo ${instances_info} | jq -r .[0].id)
    fi

    instance_info=$(get_instance ${ingress_host} ${jsession_id} ${instance_id})
    operation_info=$(echo ${operations_info} | jq --arg id "${instance_id}" '.[] | select(.vnfInstanceId == $id)')
    vnfProductName=$(echo ${instance_info} | jq -r .vnfProductName)
    instantiationState=$(echo ${instance_info}  | jq -r .instantiationState)
    operationState=$(echo ${operation_info} | jq -s -r 'sort_by(.startTime) | reverse | .[0].operationState')
    clusterName=$(echo ${operation_info}  | jq -s -r 'sort_by(.startTime) | reverse | .[0].operationParams.clusterName')
    namespace=$(echo ${operation_info}  | jq -s -r 'sort_by(.startTime) | reverse | .[0].operationParams.additionalParams.namespace')

    # Can't terminate the instance in STARTING or PROCESSING operation status
    if [[ "${operationState}" == "STARTING" ||  "${operationState}" == "PROCESSING" ]]; then
        echo "$(date +"%Y-%m-%d %H:%M:%S") ERROR: There is ongoing operation for VNF, can't be terminated. Exit!"
        exit 1
    fi

    # User confirm for termination
    echo "$(date +"%Y-%m-%d %H:%M:%S") INFO: ${terminate_vnf} instance ID is ${instance_id}"
    echo
    print_all_instances_info "$(echo ${instance_info} | jq -s .)" "$(echo ${operation_info} | jq -s .)"| column -t
    echo
    read -p "Are you sure you want to terminate above VNF, type 'y' to continue: " terminate_confirm
    if [[ "${terminate_confirm}" != "y" ]]; then
        exit 1
    fi

    # Legacy cluster name format change
    if [[ ${clusterName} == eccd* ]]; then
        testenv=$(echo ${evnfm_cluster} | cut -d'-' -f1)
        clusterName="${testenv}-${clusterName}"
    fi

    # Find kubeconfig file
    kubeconfig_file="${kubeconfig_folder}/${clusterName}.config"
    if [[ -f ${kubeconfig_file} ]] && [[ "${instantiationState}" == "INSTANTIATED" && "${operationState}" == "COMPLETED" ]]; then
        echo "$(date +"%Y-%m-%d %H:%M:%S") INFO: Kubeconfig file: ${kubeconfig_file} exsits"
        delete_operation_on_cluster="true"
        echo "$(date +"%Y-%m-%d %H:%M:%S") INFO: The VNF LCM is in normal status, the script will do kubectl operation on traffic cluster"
        echo "$(date +"%Y-%m-%d %H:%M:%S") INFO: such as deleting PCG data-plane Pods, deleting namespace after VNF termination"
    else
        echo "$(date +"%Y-%m-%d %H:%M:%S") WARNING: Kubeconfig file: ${kubeconfig_file} doesn't exsit."
        delete_operation_on_cluster="false"
    fi

    # Delete the PCG data-plance Pod forcefully before terminating
    if [[ "${vnfProductName}" == "PCG" ]]; then
        if [[ "${delete_operation_on_cluster}" == "true" ]]; then
            echo "$(date +"%Y-%m-%d %H:%M:%S") INFO: Scale in the PCG data-plane Pods in namespace \"${namespace}\" on \"${clusterName}\""
            kubectl --kubeconfig=${kubeconfig_file} -n ${namespace} scale deployment eric-pc-up-data-plane --replicas=0
            echo "$(date +"%Y-%m-%d %H:%M:%S") INFO: Wait for the data-plane Pods in Terminating status..."
            waiting 20
            echo "$(date +"%Y-%m-%d %H:%M:%S") INFO: Delete the data-plane Pods forcefully"
            kubectl --kubeconfig=${kubeconfig_file} -n ${namespace} delete pod -l app.kubernetes.io/name=eric-pc-up-data-plane --force
        else
            echo "$(date +"%Y-%m-%d %H:%M:%S") WARNING: Skip deleting the PCG data-plane Pods. Don't forget to do manual deletion if needed."
        fi
    fi 

    # ---- EVNFM LCM start ----
    # Terminate instance
    if [[ "${instantiationState}" == "INSTANTIATED" ]]; then
        echo "$(date +"%Y-%m-%d %H:%M:%S") INFO: Terminating the VNF ${terminate_vnf} on cluster ${clusterName}"
        terminate ${ingress_host} ${jsession_id} ${instance_id}
        echo "$(date +"%Y-%m-%d %H:%M:%S") INFO: Checking terminating status" 
        while true; do
            instance_info=$(get_instance ${ingress_host} ${jsession_id} ${instance_id})
            instantiationState=$(echo ${instance_info} | jq -r .instantiationState)
            operations_info=$(get_all_operations ${ingress_host} ${jsession_id})
            operation_info=$(echo ${operations_info} | jq --arg id "${instance_id}" '.[] | select(.vnfInstanceId == $id)')
            #operationState=$(echo ${operation_info} | jq -r '. | select(.operation == "TERMINATE") | .operationState')
            operationState=$(echo ${operation_info} | jq -s -r 'sort_by(.startTime) | reverse | .[0].operationState')
            echo "$(date +"%Y-%m-%d %H:%M:%S") INFO: ${terminate_vnf} instantiationState is ${instantiationState}, and the operationState is ${operationState}"
            if [[ "${instantiationState}" == "NOT_INSTANTIATED" && "${operationState}" == "COMPLETED" ]]; then
                echo "$(date +"%Y-%m-%d %H:%M:%S") INFO: The VNF ${terminate_vnf} is terminated successfully!"
                break
            elif [[ "${operationState}" == "FAILED" ]]; then
                #echo ${operation_info} | jq -r '. | select(.operation == "TERMINATE") | .error'
                echo ${operation_info} | jq -s -r 'sort_by(.startTime) | reverse | .[0].error'
                exit 1
            fi
            waiting 10
        done
    fi

    # Delete instance ID
    echo "$(date +"%Y-%m-%d %H:%M:%S") INFO: Deleting the instance ID ${instance_id}"
    delete_instance_id ${ingress_host} ${jsession_id} ${instance_id}
    status_code=$(get_instance ${ingress_host} ${jsession_id} ${instance_id} | jq -r .status)
    if [[ ${status_code} -eq 404 ]]; then
        echo "$(date +"%Y-%m-%d %H:%M:%S") INFO: The instance ID ${instance_id} was deleted successfully."
    else
        echo "$(date +"%Y-%m-%d %H:%M:%S") ERROR: Failed to delete the instance ID ${instance_id}."
        exit 1
    fi
    # ---- EVNFM LCM end ----

    # Delete namespace
    if [[ "${delete_operation_on_cluster}" == "true" ]]; then
        echo "$(date +"%Y-%m-%d %H:%M:%S") INFO: Delete the namespace \"${namespace}\" on cluster \"${clusterName}\""
        kubectl --kubeconfig=${kubeconfig_file} delete ns ${namespace}
    else
        echo "$(date +"%Y-%m-%d %H:%M:%S") WARNING: Skip deleting the namespace \"${namespace}\" on cluster \"${clusterName}\". Don't forget to do manual deletion if needed"
    fi

###########################################################
# Delete a VNF Package                                    #
###########################################################
elif [[ -z ${file_or_folder} ]] && [[ -z ${vnf_name} ]] && [[ -z ${terminate_vnf} ]] && [[ ! -z ${is_delete_package} ]] && [[ -z ${traffic_cluster} ]]; then
    echo
    print_all_packages_info "${packages_info}" | column -t
    num_packages=$(echo ${packages_info} | jq -r .[].id | wc -l)
    echo
    while true; do
        read -p "Select the VNF package list index to be deleted (0,1,2..n): " input_id
        if [[ "${input_id}" =~ ^[0-9]+$ ]] && [[ ${input_id} -gt 0 ]] && [[ ${input_id} -le ${num_packages} ]]; then
            package_id=$(echo ${packages_info} | jq -r .[$((${input_id}-1))].id)
            break
        else
            echo "Invalid input. Please try again!"
        fi
    done
    package_info=$(get_package ${ingress_host} ${jsession_id} ${package_id})
    echo
    print_package_info "${package_info}" | column -t
    echo
    read -p "Are you sure you want to delete above package, type 'y' to continue: " delete_confirm
    if [[ "${delete_confirm}" != "y" ]]; then
        exit 1
    fi
    delete_package ${ingress_host} ${jsession_id} ${package_id}
    status_code=$(get_package ${ingress_host} ${jsession_id} ${package_id} | jq -r .status)
    if [[ ${status_code} -eq 404 ]]; then
        echo "$(date +"%Y-%m-%d %H:%M:%S") INFO: The package was deleted successfully."
    else
        echo "$(date +"%Y-%m-%d %H:%M:%S") ERROR: Failed to delete the package."
    fi

###########################################################
# Define additional cluster in EVNFM                      #
###########################################################
elif [[ -z ${file_or_folder} ]] && [[ -z ${vnf_name} ]] && [[ -z ${terminate_vnf} ]] && [[ -z ${is_delete_package} ]] && [[ ! -z ${traffic_cluster} ]]; then
    echo "$(date +"%Y-%m-%d %H:%M:%S") INFO: Define the target cluster: ${traffic_cluster} in EVNFM"
    define_cluster ${ingress_host} ${jsession_id} "${script_folder}/kubeconfig/${traffic_cluster}.config"


# Error
else
    echo "$(date +"%Y-%m-%d %H:%M:%S") ERROR: Too many options! No more than one option in '-o', '-i', '-t', '-d' and '-r'."
fi
