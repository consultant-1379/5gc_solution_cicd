echo "label the first standard worker for pcc-mm-pod=controller"
for i in `kubectl get node | awk '{print $1}'|egrep 'pool1|pool3'|head -n 2`
do
echo "label worker $i"
kubectl label node $i pcc-mm-pod=controller
done


echo "label all standard workers except the first two for pcc-mm-pod=mobility"

export count=`kubectl get node | awk '{print $1}'|egrep 'pool1|pool3' | wc -l `
export New_count=`expr $count - 2`
for i in `kubectl get node | awk '{print $1}'|egrep 'pool1|pool3' |tail -n $New_count`
do
echo "label worker $i"
kubectl label node $i pcc-mm-pod=mobility
done


 
echo "label the last two standard workers for pcc-sm-pod=controller"

for i in `kubectl get node | awk '{print $1}'|egrep 'pool1|pool3' | tail -f -n2`
do
echo "label worker $i"
kubectl label node $i pcc-sm-pod=controller
done



echo "label all standard workers except the last two for pcc-sm-pod=session"

for i in `kubectl get node | awk '{print $1}'|egrep 'pool1|pool3' |head -n $New_count`
do
echo "label worker $i"
kubectl label node $i pcc-sm-pod=session
done


echo "label all standard wokers except the first two and the last two for pcc-obj-sto-mn-pod=obj-sto-mn"

export New_count_1=`expr $count - 4`
for i in `kubectl get node | awk '{print $1}'|egrep 'pool1|pool3' |tail -n $New_count|sort -r | tail -n $New_count_1`
do
echo "label worker $i"
kubectl label node $i pcc-obj-sto-mn-pod=obj-sto-mn
kubectl label node $i pcc-sm-pod=non-controller
kubectl label node $i pcc-mm-pod=non-controller
done


echo "label all standard wokers  the first two and the last two for pcc-obj-sto-mn-pod=controller"

for i in `kubectl get node | awk '{print $1}'|egrep 'pool1|pool3' |head -n 2`
do
echo "label worker $i"
kubectl label node $i pcc-obj-sto-mn-pod=controller
done

for i in `kubectl get node | awk '{print $1}'|egrep 'pool1|pool3' |tail -f -n2`
do
echo "label worker $i"
kubectl label node $i pcc-obj-sto-mn-pod=controller
done
