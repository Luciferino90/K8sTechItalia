#!/bin/bash

K8S_YAML_DIR=/Users/luca/workbench/techitalia/Kubernetes/
JAVA_PROJECT_DIR=/Users/luca/workbench/techitalia/Java/sparkstream

cd $K8S_YAML_DIR

kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.0.0-beta6/aio/deploy/recommended.yaml
#kubectl apply -f 17_kubernetes-dashboard-svc.yaml
kubectl apply -f 1_registry_ns.yaml
kubectl apply -f 6_techitalia_mongo_secret.yaml
kubectl apply -f 7_techitalia_mongo_depl.yaml
kubectl apply -f 8_techitalia_mongo_service.yaml
kubectl apply -f 2_kube_registry_rs.yaml
kubectl apply -f 3_kube_registry_service.yaml
kubectl apply -f 4_kube_registry_proxy_ds.yaml
kubectl apply -f 5_techiitalia_ns.yaml
kubectl apply -f 9_techitalia_kafka_depl.yaml
kubectl apply -f 10_techitalia_kafka_service.yaml
kubectl apply -f 11_techitalia_kafka_manager_depl.yaml
kubectl apply -f 12_techitalia_kafka_manager_service.yaml
kubectl apply -f 13_techitalia_connect_secret.yaml

sleep 30
docker build -t connect:0.0.2 .
docker tag connect:0.0.2 localhost:5000/connect:0.0.2
docker push localhost:5000/connect:0.0.2

sleep 30 
MONGO_POD_NAME=$(kubectl get pods --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}' --namespace=techitalia | grep mongo)
kubectl exec -it --namespace=techitalia "$MONGO_POD_NAME" -- bash -c "mongo -u tech -p italia --authenticationDatabase techitalia --eval \"db.getSiblingDB('techitalia').createCollection('documents')\""
kubectl exec -it --namespace=techitalia "$MONGO_POD_NAME" -- bash -c "mongo -u tech -p italia --authenticationDatabase techitalia --eval \"db.getSiblingDB('techitalia').createCollection('movies')\""
kubectl apply -f 14_techitalia_connect_depl.yaml

cd $SPARK_HOME
docker build -t spark-home:latest -f kubernetes/dockerfiles/spark/Dockerfile .
docker tag spark-home:latest localhost:5000/spark-home:latest
docker push localhost:5000/spark-home:latest

cd $JAVA_PROJECT_DIR
mvn clean compile package install

docker build -t tech-spark:latest --build-arg JAR_FILE=mongo-spark-streaming-launch.jar --build-arg JAR_VERSION=0.0.1 --build-arg START_CLASS=it.arubapec.esecurity.mongostreamspark.SpringKafkaApplication .

docker tag tech-spark:latest localhost:5000/tech-spark:latest
docker push localhost:5000/tech-spark:latest

cd $SPARK_HOME
nohup bin/spark-submit \
	--master k8s://https://kubernetes.docker.internal:6443 \
	--deploy-mode cluster \
	--conf spark.executor.instances=2 \
	--conf spark.kubernetes.authenticate.driver.serviceAccountName=default \
	--conf spark.kubernetes.container.image=localhost:5000/tech-spark:latest \
	--class it.arubapec.esecurity.mongostreamspark.SpringKafkaApplication \
	--conf "spark.executor.extraJavaOptions=-Dlog4j.configuration=file:/app/log4j.properties" \
	--conf "spark.driver.extraJavaOptions=-Dlog4j.configuration=file:/app/log4j.properties" \
	--name spark-pi \
	-v \
	local:///opt/spark/examples/jars/app.jar/app.jar \
	-Dlog4j.debug=true \
	-Dlog4j.configuration=file:/app/log4j.properties

cd $K8S_YAML_DIR
kubectl apply -f 15_zeppelin-server.yaml
kubectl apply -f 16_zeppelin-svc.yaml
