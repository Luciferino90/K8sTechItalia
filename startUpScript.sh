#!/bin/bash
kubectl apply -f 1_registry_ns.yaml
kubectl apply -f 2_kube_registry_rs.yaml
kubectl apply -f 3_kube_registry_service.yaml
kubectl apply -f 4_kube_registry_proxy_ds.yaml
kubectl apply -f 5_techiitalia_ns.yaml
kubectl apply -f 6_techitalia_mongo_secret.yaml
kubectl apply -f 7_techitalia_mongo_depl.yaml
kubectl apply -f 8_techitalia_mongo_service.yaml
# replica wait time
sleep 70 
MONGO_POD_NAME=$(kubectl get pods --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}' --namespace=techitalia | grep mongo)
kubectl exec -it --namespace=techitalia "$MONGO_POD_NAME" -- bash -c "mongo -u tech -p italia --authenticationDatabase techitalia --eval \"db.getSiblingDB('techitalia').createCollection('documents')\""
kubectl exec -it --namespace=techitalia "$MONGO_POD_NAME" -- bash -c "mongo -u tech -p italia --authenticationDatabase techitalia --eval \"db.getSiblingDB('techitalia').createCollection('movies')\""
kubectl apply -f 9_techitalia_kafka_depl.yaml
kubectl apply -f 10_techitalia_kafka_service.yaml
kubectl apply -f 11_techitalia_kafka_manager_depl.yaml
kubectl apply -f 12_techitalia_kafka_manager_service.yaml
kubectl apply -f 13_techitalia_connect_secret.yaml
docker build -t connect:0.0.2 .
docker tag connect:0.0.2 localhost:5000/connect:0.0.2
docker push localhost:5000/connect:0.0.2
kubectl apply -f 14_techitalia_connect_depl.yaml
