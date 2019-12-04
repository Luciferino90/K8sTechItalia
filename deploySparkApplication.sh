#!/bin/bash
kubectl delete ns techitalia
kubectl delete CustomResourceDefinition scheduledsparkapplications.sparkoperator.k8s.io -n techitalia
kubectl delete CustomResourceDefinition sparkapplications.sparkoperator.k8s.io -n techitalia
kubectl delete pv parquet-pv
#helm install incubator/sparkoperator --namespace techitalia --set enableWebhook=true --generate-name
# kubectl apply -f SparkOperator/techitalia-spark-operator_docker.yaml
# sh InstallFromDocker.sh