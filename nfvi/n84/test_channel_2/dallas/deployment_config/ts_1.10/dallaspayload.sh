file="/var/log/dallas_pm.log"

echo  $# 
if [ $# -eq 2 ]
  then
    file=$2
fi

lts_pmshow -f $file -c "LTT Payload - Gi UL bytes - Value;LTT Payload - Gi UL packets - Value;LTT Payload - Gn/Iuu DL bytes - Value;LTT Payload - Gn/Iuu DL packets - Value;LTT Payload - Gi DL bytes - Value;LTT Payload - Gi DL packets - Value;LTT Payload - Gn/Iuu UL bytes - Value;LTT Payload - Gn/Iuu UL packets - Value" -x -j | awk -F ";" '{ printf("%s, ULtx/rx: %1.2f / %1.2f Gbps (%4.2d / %1.2d kpps / %3.2f%%)  DLtx/rx: %5.2f / %1.2f Gbps (%4.2d / %1.2d kpps / %3.2f%%),  Total_rx: %4.1f Gbps (%4.2d kpps), UL/DL_pps: %2.1f/%2.1f%, UL/DL_bw: %2.1f/%2.1f%, UL/DL/AVG_pktsize: %2d/%2d/%2d \n", $1, $8*8/1000000000, $2*8/1000000000, $9/1000, $3/1000,100*($3/($9+0.000000000001)),$6*8/1000000000, $4*8/1000000000,$7/1000, $5/1000, 100*($5/($7+0.000000000001)), $2*8/1000000000+$4*8/1000000000,$3/1000+$5/1000, $3/($5+$3+0.000000001)*100, $5/($5+$3+0.000000001)*100, $2/(0.000001+$2+$4)*100,$4/(0.000000001+$2+$4)*100, $8/($9+0.00000000001), $6/($7+0.00000000001), ((($3/($5+$3+0.000000001))  * ($8/($9+0.00000000001))) + (($6/($7+0.00000000001) ) * ($5/($5+$3+0.000000001))))  )}'

#$8/($9+0.00000000001) UL pktsize
#$6/($7+0.00000000001) DL pktsize

#$3/($5+$3+0.000000001) UL packets
#$5/($5+$3+0.000000001) DL packets

#(($2/(0.000001+$2+$4)) * ($8/($9+0.00000000001))()+(($4/(0.000000001+$2+$4)) * ($6/($7+0.00000000001))))


#((($3/($5+$3+0.000000001))  * ($8/($9+0.00000000001))) + (($6/($7+0.00000000001) ) * ($5/($5+$3+0.000000001))))
