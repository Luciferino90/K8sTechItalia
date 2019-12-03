#!/bin/bash

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
REGISTRY_SHARED=$SHARED_DIRS/registry
mkdir -p $REGISTRY_SHARED
PARQUET_SHARED=$SHARED_DIRS/parquet
mkdir -p $PARQUET_SHARED

DASHBOARD_HOME=$SRC_HOME/Dashboard
mkdir -p $DASHBOARD_HOME
KAFKA_HOME=$SRC_HOME/Kafka
mkdir -p $KAFKA_HOME
KAFKA_CONNECT_HOME=$SRC_HOME/KafkaConnect
mkdir -p $KAFKA_CONNECT_HOME
MONGO_HOME=$SRC_HOME/MongoDB
mkdir -p $MONGO_HOME
REGISTRY_HOME=$SRC_HOME/Registry
mkdir -p $REGISTRY_HOME
ZEPPELIN_HOME=$SRC_HOME/Zeppelin
mkdir -p $ZEPPELIN_HOME
SPARK_FOLDER=spark-2.4.4-bin-hadoop2.7
SPARK_FALLBACK_HOME=$SRC_HOME/$SPARK_FOLDER
mkdir -p $SPARK_FALLBACK_HOME
SPARK_OPERATOR_HOME=$SRC_HOME/SparkOperator
mkdir -p $SPARK_OPERATOR_HOME

cp -r Dashboard/* $DASHBOARD_HOME/
cp -r Kafka/* $KAFKA_HOME/
cp -r KafkaConnect/* $KAFKA_CONNECT_HOME/
cp -r MongoDB/* $MONGO_HOME/
cp -r Registry/* $REGISTRY_HOME/
cp -r Zeppelin/* $ZEPPELIN_HOME/
cp -r $SPARK_FOLDER/* $SPARK_FALLBACK_HOME/
cp -r SparkOperator/* $SPARK_OPERATOR_HOME/

cp $REGISTRY_HOME/daemon.json $HOME/.docker
cp Dockerfile_Spark $SPARK_FALLBACK_HOME/kubernetes/dockerfiles/spark
rm $SPARK_FALLBACK_HOME/kubernetes/dockerfiles/spark/Dockerfile
mv $SPARK_FALLBACK_HOME/kubernetes/dockerfiles/spark/Dockerfile_Spark $SPARK_FALLBACK_HOME/kubernetes/dockerfiles/spark/Dockerfile

sed -i.bak "s+REPLACE_ME+$MONGODB_SHARED+g" $MONGO_HOME/mongodb_deployment.yaml && rm $MONGO_HOME/mongodb_deployment.yaml.bak
sed -i.bak "s+REPLACE_ME+$REGISTRY_SHARED+g" $REGISTRY_HOME/kube_registry_rs.yaml && rm $REGISTRY_HOME/kube_registry_rs.yaml.bak
sed -i.bak "s+REPLACE_ME+$PARQUET_SHARED+g" $SPARK_OPERATOR_HOME/techitalia-spark-operator.yaml && rm $SPARK_OPERATOR_HOME/techitalia-spark-operator.yaml.bak
sed -i.bak "s+REPLACE_ME+$PARQUET_SHARED+g" $ZEPPELIN_HOME/zeppelin-server.yaml && rm $ZEPPELIN_HOME/zeppelin-server.yaml.bak

#if [ -d $SPARK_HOME ] ;
#then 
#	echo "SPARK_HOME FOUND $SPARK_HOME"
#else
#	SPARK_HOME=$SPARK_FALLBACK_HOME
#	echo "SPARK_HOME NOT FOUND SETTED DEFAULT $SPARK_HOME as $SPARK_FALLBACK_HOME"
#fi

SPARK_HOME=$SPARK_FALLBACK_HOME

echo "Environment setup ended"
echo

echo "Setup Kubernetes Dashboard on K8s"
echo

cd $DASHBOARD_HOME
kubectl apply -f dashboard.yaml
kubectl get secret | awk '{print $1}' | kubectl describe secret $1 | awk '/ey/' | awk '{print "Dashboard Token Here ---> " $2}'

echo "Setup Docker Registry on K8s"
echo

cd $REGISTRY_HOME
kubectl apply -f kube_registry_ns.yaml
kubectl apply -f kube_registry_rs.yaml
kubectl apply -f kube_registry_service.yaml
kubectl apply -f kube_registry_proxy_ds.yaml

echo "Setup MongoDB on K8s"
echo

cd $MONGO_HOME
kubectl apply -f techitalia_ns.yaml
kubectl apply -f mongodb_secret.yaml
kubectl apply -f mongodb_deployment.yaml
kubectl apply -f mondodb_service.yaml

echo "Waiting for MongoDB to be up & running.."
echo

sleep 60

echo "Setup Kafka and Zookeeper on K8s"
echo

cd $KAFKA_HOME
kubectl apply -f kafka_deployment.yaml
kubectl apply -f kafka_service.yaml
kubectl apply -f kafka_manager_deployment.yaml
kubectl apply -f kafka_manager_service.yaml

echo "Setup Kafka Connect via Docker Registry"
echo "Waiting for registry to be up & running.."
echo

sleep 60
cd $KAFKA_CONNECT_HOME
docker build -t connect:0.0.2 .
docker tag connect:0.0.2 registry.me:5000/connect:0.0.2
docker push registry.me:5000/connect:0.0.2

echo "Waiting for MongoDB to be up & running.."
echo

echo "Initializing base data for MongoDB"
echo

sleep 60
MONGO_POD_NAME=$(kubectl get pods --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}' --namespace=techitalia | grep mongo)
kubectl exec -it --namespace=techitalia "$MONGO_POD_NAME" -- bash -c "mongo -u tech -p italia --authenticationDatabase techitalia --eval \"db.getSiblingDB('techitalia').createCollection('documents')\""
kubectl exec -it --namespace=techitalia "$MONGO_POD_NAME" -- bash -c "mongo -u tech -p italia --authenticationDatabase techitalia --eval \"db.getSiblingDB('techitalia').createCollection('movies')\""

echo "Setup Kafka Connect on K8s"
echo

kubectl apply -f kafka_connect_secret.yaml
kubectl apply -f kafka_connect_deployment.yaml


echo "Setup Spark Image via Docker Registry"
echo

cd $SPARK_HOME
docker build -t spark-home:latest -f kubernetes/dockerfiles/spark/Dockerfile .
docker tag spark-home:latest registry.me:5000/spark-home:latest
docker push registry.me:5000/spark-home:latest

cd $HOME_DIR/sparkstream
echo "Building Java Spark project"
echo
docker build -t tech-spark:latest --build-arg JAR_FILE=mongo-spark-streaming-launch.jar --build-arg JAR_VERSION=0.0.1 --build-arg START_CLASS=it.arubapec.esecurity.mongostreamspark.SpringKafkaApplication .
docker tag tech-spark:latest registry.me:5000/tech-spark:latest
docker push registry.me:5000/tech-spark:latest

cd $SPARK_OPERATOR_HOME
echo "Setup Spark K8s Operators"
echo
helm repo add incubator http://storage.googleapis.com/kubernetes-charts-incubator
helm install incubator/sparkoperator --namespace techitalia --set enableWebhook=true --generate-name
kubectl apply -f techitalia-spark-operator.yaml

echo "Setup Zeppelin Image via Docker Registry"
echo

cd $ZEPPELIN_HOME
docker build -t zeppelin-home:latest .
docker tag zeppelin-home:latest registry.me:5000/zeppelin-home:latest
docker push registry.me:5000/zeppelin-home:latest

echo "Setup Zeppelin on K8s"
echo
kubectl apply -f zeppelin-server.yaml

TOKEN=$(kubectl get secret | awk '{print $1}' | kubectl describe secret $1 | awk '/ey/' | awk '{print $2}')
echo
echo
echo "Installation ended, login via https://localhost with token:"
echo "$TOKEN"

