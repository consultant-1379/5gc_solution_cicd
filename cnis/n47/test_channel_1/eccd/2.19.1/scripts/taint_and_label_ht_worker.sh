for i in `kubectl get node |grep -i pool2|awk '{print $1}'`
do
echo "taint HT Worker Node $i"
kubectl taint node $i sriov=true:NoSchedule
kubectl label node $i plane=data
done

