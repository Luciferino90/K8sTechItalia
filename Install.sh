#!/bin/bash

mkdir -p /Users/luca/kubernetes/mongodb
mkdir -p /Users/luca/kubernetes/registry

K8S_HOME=/Users/luca/workbench/techitalia/Kubernetes
DASHBOARD_HOME=$K8S_HOME/Dashboard
KAFKA_HOME=$K8S_HOME/Kafka
KAFKA_CONNECT_HOME=$K8S_HOME/KafkaConnect
MONGO_HOME=$K8S_HOME/MongoDB
REGISTRY_HOME=$K8S_HOME/Registry
SPARK_HOME=$K8S_HOME/Spark
ZEPPELIN_HOME=$K8S_HOME/Zeppelin


if [ -d $SPARK_HOME ]
then 
	echo "SPARK_HOME FOUND $SPARK_HOME"
else
	SPARK_HOME=$K8S_HOME/spark-2.4.4-bin-hadoop2.7
	echo "SPARK_HOME NOT FOUND SETTED DEFAULT $SPARK_HOME"
fi

cd $REGISTRY_HOME
cp daemon.json /Users/luca/.docker

cd $DASHBOARD_HOME
kubectl apply -f dashboard.yaml
kubectl get secret | awk '{print $1}' | kubectl describe secret $1 | awk '/ey/' | awk '{print "Dashboard Token Here ---> " $2}'

cd $REGISTRY_HOME
kubectl apply -f kube_registry_ns.yaml
kubectl apply -f kube_registry_rs.yaml
kubectl apply -f kube_registry_service.yaml
kubectl apply -f kube_registry_proxy_ds.yaml

cd $MONGO_HOME
kubectl apply -f techitalia_ns.yaml
kubectl apply -f mongodb_secret.yaml
kubectl apply -f mongodb_deployment.yaml
kubectl apply -f mondodb_service.yaml

echo "Waiting for MongoDB to be up & running.."
sleep 30

cd $KAFKA_HOME
kubectl apply -f kafka_deployment.yaml
kubectl apply -f kafka_service.yaml
kubectl apply -f kafka_manager_deployment.yaml
kubectl apply -f kafka_manager_service.yaml

echo "Waiting for registry to be up & running.."
sleep 30
cd $KAFKA_CONNECT_HOME
docker build -t connect:0.0.2 .
docker tag connect:0.0.2 localhost:5000/connect:0.0.2
docker push localhost:5000/connect:0.0.2

echo "Waiting for MongoDB to be up & running.."
sleep 30
MONGO_POD_NAME=$(kubectl get pods --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}' --namespace=techitalia | grep mongo)
kubectl exec -it --namespace=techitalia "$MONGO_POD_NAME" -- bash -c "mongo -u tech -p italia --authenticationDatabase techitalia --eval \"db.getSiblingDB('techitalia').createCollection('documents')\""
kubectl exec -it --namespace=techitalia "$MONGO_POD_NAME" -- bash -c "mongo -u tech -p italia --authenticationDatabase techitalia --eval \"db.getSiblingDB('techitalia').createCollection('movies')\""
kubectl apply -f kafka_connect_secret.yaml
kubectl apply -f kafka_connect_deployment.yaml

cd $SPARK_HOME
docker build -t spark-home:latest -f kubernetes/dockerfiles/spark/Dockerfile .
docker tag spark-home:latest localhost:5000/spark-home:latest
docker push localhost:5000/spark-home:latest

cd $ZEPPELIN_HOME
docker build -t zeppelin-home:latest .
docker tag zeppelin-home:latest localhost:5000/zeppelin-home:latest
docker push localhost:5000/zeppelin-home:latest
kubectl apply -f zeppelin-server.yaml
