#!/bin/bash

# 2015-09-23: ervmapa
# adding variable -r for resetting diff values. Example  -r "17:43:00"

################################################################################
# lts_pmshow for combined node under test
###############################################################################
pmshow_cgw () {
/lab/epg_st_utils/testtools/dallas/rhel6.x86_64/R10A99/mnsserv/bin/lts_pmshow ${file} -c 'System - Total signaling - Rate;Total signaling KPI - Attempted;Total signaling KPI - Failed;NR - Active PDU Session Number - Value;LTT Payload - Gi UL bytes - Rate;LTT Payload - Gn/Iuu DL bytes - Rate;LTT Payload - Uplink Packets dropped \(E2E\) - Value;LTT Payload - Downlink Packets dropped \(E2E\) - Value;LTT Payload - Gi DL packets - Value;LTT Payload - Gn/Iuu UL packets - Value;LTT Payload - Gi UL packets - Rate;LTT Payload - Gn/Iuu DL packets - Rate;NR - Inactive PDU Session Number - Value;NR - RM-REGISTERED UE Number - Value;NR - RM-REGISTERED CM-IDLE UE Number - Value;LTE - Attached CM-CONNECTED UE - Value;LTE - Attached CM-IDLE UE - Value;'  | awk -v showdelta=${delta} -v showverbose=${verbose} -v offset_ul=0 -v offset_dl=0  -v pud=0 -v pdd=0 -v ref_time=${ref_time} '{
    date=$1
    if (date != "Time")
    {
      if (date ~ /^20[0-9][0-9]-/)
      {
        time=$2
        tsr=$3
        tsa=$4
        tsf=$5
        tap=$6
        pgubr=$7*8/1000/1000/1000
        pgdbr=$8*8/1000/1000/1000
        pudd=$9-pud
        pddd=$10-pdd
        pud=$9
        pdd=$10
        puv=$11
        pdv=$12
        pps=$14+$13
        idlPdu=$15
        RegUe=$16
        idleUe=$17
        lteUE=$18+$19
        ppm_1minute_mean=(pudd+pddd)/60/(pps+0.0001)*1000000
        if (tsa==0) tsa=0.00001
        ppm=(pud+pdd)/(puv+pdv+0.0000001)
        if (showdelta ~ /true/)
         {
          format="%-10s  %-8s  %11i  %14.5f  %16i  %13.4f  %13.5f  %11i  %11i  %11i %10i %8.2f   %10i  %10i  %10i\n"
          printf format, date, time, tsr, (1-tsf/tsa)*100, tap+idlPdu, pgubr, pgdbr, pudd, pddd, $9+$10,  pps, ppm*1000000, ppm_1minute_mean, RegUe,    lteUE
        } else {
          format="%-10s  %-8s  %10i  %13.1f  %10i  %13.1f\n"
          printf format, date, time, uldiff, 1000000*(uldiff)/(gnul+0.001), dldiff, 1000000*(dldiff)/(gidl+0.001)
        }
      }
    } else {
      if (showdelta ~ /true/)
      {
        print "Date        Time         signal_rate    signaling_KPI(%)       total_PDU     uplink_G   downlink_G      ul_drop      dl_drop    total_drop     pps     ppm_total     ppm_1min   5GSAU       4GSAU"
        print "------      -----         -------       ------------            -------      --------    ---------      -------      ------       -----        ---        ---        ----         ---        --- "
      } else {
        print "Date        Time      UL diff     UL loss [ppm]  DL diff     DL loss [ppm]"
        print "----------  --------  ----------  -------------  ----------  -------------"
      }
    }
  }'

}

################################################################################
# MAIN
################################################################################

# Parse command line
file=""
delta="true"
verbose="false"
loop="true"
ref_time="false"
interval=60

while getopts ":r:f:dvhtn" opts
do
  case "$opts" in
    "f") file="-f $OPTARG/dallas_pm.log";;
    "d") delta="true";;
    "v") verbose="true";;
    "t") loop="true";;
    "n") loop="False";;
    "r") ref_time="$OPTARG";;
    "i") interval="$OPTARG";;
    "h") usage ;;
    "?") ${ECHO}
         ${ECHO} "ERROR: Unknown option '$OPTARG'!"
         ${ECHO}
         exit 1;;
    ":") ${ECHO}
         ${ECHO} "ERROR: Missing value for option '$OPTARG'!"
         ${ECHO}
         exit 1;;
  esac
done

  if [ "${loop}" == "true" ];
  then
    while [ 1 ]
    do
      pmshow_cgw
      sleep $interval
    done
  else
    pmshow_cgw
  fi
