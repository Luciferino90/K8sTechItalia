#!/bin/bash

unameOut="$(uname -s)"
GENERATE_NAME=""
case "${unameOut}" in
    Linux*)     LOCAL_BASE_PATH=/;; #MACHINE=Linux;;
    Darwin*)    LOCAL_BASE_PATH=/;GENERATE_NAME=--generate-name;; #MACHINE=Mac;;
    CYGWIN*)    LOCAL_BASE_PATH=/c;GENERATE_NAME=--generate-name;; #MACHINE=Cygwin;;
    MINGW*)     LOCAL_BASE_PATH=/c;GENERATE_NAME=--generate-name;; #MACHINE=MinGw;;
    *)          LOCAL_BASE_PATH=/;; #MACHINE="UNKNOWN:${unameOut}"
esac

POD_PARQUET_MOUNT_PATH=/zeppelin/k8s-custom
LOCAL_PARQUET_MOUNT_PATH=$LOCAL_BASE_PATH$POD_PARQUET_MOUNT_PATH
NAMESPACE=techitalia
REGISTRY_HOST=luciferino
mkdir -p $LOCAL_PARQUET_MOUNT_PATH

echo
echo "Setup environment starting"
echo

HOME_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

K8S_HOME=$HOME/.kubernetes
SRC_HOME=$K8S_HOME/src
mkdir -p $SRC_HOME
SHARED_DIRS=$K8S_HOME/shared
mkdir -p $SHARED_DIRS

MONGODB_SHARED=$SHARED_DIRS/mongodb
mkdir -p $MONGODB_SHARED
PARQUET_SHARED=$SHARED_DIRS/parquet
mkdir -p $PARQUET_SHARED

echo HOME_DIR
cp -r yaml/* $SRC_HOME
cd $SRC_HOME

sed -i.bak "s+REPLACE_NAMESPACE+$NAMESPACE+g" 1-namespace.yaml && rm 1-namespace.yaml.bak
sed -i.bak "s+REPLACE_NAMESPACE+$NAMESPACE+g" 2-mondodb_service.yaml && rm 2-mondodb_service.yaml.bak
sed -i.bak "s+REPLACE_NAMESPACE+$NAMESPACE+g" 3-mongodb_secret.yaml && rm 3-mongodb_secret.yaml.bak
sed -i.bak "s+REPLACE_NAMESPACE+$NAMESPACE+g" 4-mongodb_deployment.yaml && rm 4-mongodb_deployment.yaml.bak
sed -i.bak "s+REPLACE_NAMESPACE+$NAMESPACE+g" 5-parquet-persistence.yaml && rm 5-parquet-persistence.yaml.bak
sed -i.bak "s+REPLACE_NAMESPACE+$NAMESPACE+g" 6-kafka_service.yaml && rm 6-kafka_service.yaml.bak
sed -i.bak "s+REPLACE_NAMESPACE+$NAMESPACE+g" 7-kafka_deployment.yaml && rm 7-kafka_deployment.yaml.bak
sed -i.bak "s+REPLACE_NAMESPACE+$NAMESPACE+g" 8-kafka_manager_service.yaml && rm 8-kafka_manager_service.yaml.bak
sed -i.bak "s+REPLACE_NAMESPACE+$NAMESPACE+g" 9-kafka_manager_deployment.yaml && rm 9-kafka_manager_deployment.yaml.bak
sed -i.bak "s+REPLACE_NAMESPACE+$NAMESPACE+g" 10-kafka_connect_secret.yaml && rm 10-kafka_connect_secret.yaml.bak
sed -i.bak "s+REPLACE_NAMESPACE+$NAMESPACE+g" 11-kafka_connect_deployment.yaml && rm 11-kafka_connect_deployment.yaml.bak
sed -i.bak "s+REPLACE_NAMESPACE+$NAMESPACE+g" 12-techitalia_populator.yaml && rm 12-techitalia_populator.yaml.bak
sed -i.bak "s+REPLACE_NAMESPACE+$NAMESPACE+g" 13-techitalia_spark_operator.yaml && rm 13-techitalia_spark_operator.yaml.bak
sed -i.bak "s+REPLACE_NAMESPACE+$NAMESPACE+g" 14-zeppelin_server.yaml && rm 14-zeppelin_server.yaml.bak

sed -i.bak "s+REPLACE_PARQUET_MOUNT+$LOCAL_PARQUET_MOUNT_PATH+g" 5-parquet-persistence.yaml && rm 5-parquet-persistence.yaml.bak
sed -i.bak "s+REPLACE_PARQUET_MOUNT+$POD_PARQUET_MOUNT_PATH+g" 13-techitalia_spark_operator.yaml && rm 13-techitalia_spark_operator.yaml.bak
sed -i.bak "s+REPLACE_PARQUET_MOUNT+$POD_PARQUET_MOUNT_PATH+g" 14-zeppelin_server.yaml && rm 14-zeppelin_server.yaml.bak

sed -i.bak "s+REPLACE_REGISTRY+$REGISTRY_HOST+g" 11-kafka_connect_deployment.yaml && rm 11-kafka_connect_deployment.yaml.bak
sed -i.bak "s+REPLACE_REGISTRY+$REGISTRY_HOST+g" 12-techitalia_populator.yaml && rm 12-techitalia_populator.yaml.bak
sed -i.bak "s+REPLACE_REGISTRY+$REGISTRY_HOST+g" 13-techitalia_spark_operator.yaml && rm 13-techitalia_spark_operator.yaml.bak
sed -i.bak "s+REPLACE_REGISTRY+$REGISTRY_HOST+g" 14-zeppelin_server.yaml && rm 14-zeppelin_server.yaml.bak

SPARK_HOME=$SPARK_FALLBACK_HOME

echo "Environment setup ended"
echo

echo "Setup MongoDB on K8s"
echo

kubectl apply -f 1-namespace.yaml
kubectl apply -f 2-mondodb_service.yaml
kubectl apply -f 3-mongodb_secret.yaml
kubectl apply -f 4-mongodb_deployment.yaml
kubectl apply -f 5-parquet-persistence.yaml

echo "Waiting for MongoDB to be up & running.."
echo

sleep 40

echo "Setup Kafka and Zookeeper on K8s"
echo

kubectl apply -f 6-kafka_service.yaml
kubectl apply -f 7-kafka_deployment.yaml
kubectl apply -f 8-kafka_manager_service.yaml
kubectl apply -f 9-kafka_manager_deployment.yaml

sleep 30

MONGO_POD_NAME=$(kubectl get pods --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}' --namespace=techitalia | grep mongo)
kubectl exec -it --namespace=techitalia "$MONGO_POD_NAME" -- bash -c "mongo -u tech -p italia --authenticationDatabase techitalia --eval \"db.getSiblingDB('techitalia').createCollection('documents')\""
kubectl exec -it --namespace=techitalia "$MONGO_POD_NAME" -- bash -c "mongo -u tech -p italia --authenticationDatabase techitalia --eval \"db.getSiblingDB('techitalia').createCollection('internaldocuments')\""

echo "Setup Kafka Connect on K8s"
echo

kubectl apply -f 10-kafka_connect_secret.yaml
kubectl apply -f 11-kafka_connect_deployment.yaml

kubectl apply -f 12-techitalia_populator.yaml

echo "Setup Spark K8s Operators"
echo
helm repo add incubator http://storage.googleapis.com/kubernetes-charts-incubator
helm install incubator/sparkoperator --namespace techitalia --set enableWebhook=true $GENERATE_NAME
kubectl apply -f 13-techitalia_spark_operator.yaml

echo "Setup Zeppelin on K8s"
echo
kubectl apply -f 14-zeppelin_server.yaml

TOKEN=$(kubectl get secret | awk '{print $1}' | kubectl describe secret $1 | awk '/ey/' | awk '{print $2}')
echo
echo
echo "Installation ended, login via https://localhost with token:"
echo "$TOKEN"
