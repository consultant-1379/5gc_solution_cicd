export count=`kubectl get node | awk '{print $1}'|egrep 'pool1|pool3' | wc -l `
export New_count=`expr $count - 2`
export New_count_1=`expr $count - 4`
for i in `kubectl get node | awk '{print $1}'|egrep 'pool1|pool3' |tail -n $New_count|sort -r | tail -n $New_count_1`
do
echo "label worker $i"
kubectl label node $i pcc-sm-pod=non-controller --overwrite
kubectl label node $i pcc-mm-pod=non-controller --overwrite
kubectl label node $i adp-snmp-ap-deploy=common
done

