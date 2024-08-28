#!/usr/bin/env bash
set -eu

SSH_OPTIONS=(-o 'UserKnownHostsFile=/dev/null' -o 'StrictHostKeyChecking=no' -o 'ServerAliveInterval=30' -o 'LogLevel=ERROR')

function info {
    date="$(date "+%Y%m%d-%H:%M:%S")"
    echo "${date} [INFO]: $*"
}

function error {
    date="$(date "+%Y%m%d-%H:%M:%S")"
    echo "${date} [ERROR]: $*"
}

function get_node_config_data() {
    local filter=${1}
    jq -r "${filter}" "${NODE_CONFIG}"
}

master_ip=$(get_node_config_data '.stpData.Common_Params.master_ip')
info "CCD master IP: ${master_ip}"

readonly ssh_master="ssh ${SSH_OPTIONS[@]} eccd@${master_ip}"
# Since we want $1 variable expanded by the client
# shellcheck disable=SC2029
${ssh_master} mkdir -p /home/eccd/evnfm/logs >> /dev/null

info "# ----------------------------------------------------------------------"
info "# Postbuild  Step.1: Collecting ADP log files on CCD master: ${master_ip}"
info "# ----------------------------------------------------------------------"
${ssh_master} /home/eccd/evnfm/script/collect_ADP_logs.sh "${1}"
${ssh_master} mv /home/eccd/logs_evnfm_*.tgz /home/eccd/evnfm/logs

info "# ----------------------------------------------------------------------"
info "# Postbuild  Step.2: Collecting evnfm install log files on CCD master: ${master_ip}"
info "# ----------------------------------------------------------------------"
${ssh_master} kubectl cp "cnis-evnfm-controller:/evnfm/logs" "/home/eccd/evnfm/logs" >> /dev/null
#${ssh_master} kubectl cp "cnis-evnfm-controller:/evnfm/prepare_site_values_*.yaml" "/home/eccd/evnfm/logs" >> /dev/null
if [[ -n $2 ]]; then
    scp -r eccd@${master_ip}:/home/eccd/evnfm/logs/* ${2}
fi