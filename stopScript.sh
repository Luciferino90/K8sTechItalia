kubectl delete deployments connect kafka kafka-manager mongodb -n techitalia
#kubectl delete rc kube-registry-v0 -n registry
#kubectl delete ds kube-registry-proxy -n registry
kubectl get po | awk '/spark/ {print $1}' | xargs kubectl delete po
kubectl delete po zeppelin-server
