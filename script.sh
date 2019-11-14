#/bin/bash!
kubectl apply -f 0\ -\ Create\ Namespaces.yaml
kubectl apply -f 1\ -\ MongoDB.yaml
kubectl apply -f 2\ -\ Kafka.yaml
kubectl apply -f 3\ -\ Kafka\ Manager.yaml
kubectl apply -f 4\ -\ SourceConnector.yaml
docker build -t connect:0.0.2 .
docker tag connect:0.0.2 localhost:5000/connect:0.0.2
docker push localhost:5000/connect:0.0.2
kubectl apply -f 0\ -\ Create\ Namespaces.yaml
kubectl apply -f 1\ -\ MongoInit.yaml
kubectl apply -f 2\ -\ MongoDB.yaml
kubectl apply -f 3\ -\ Kafka.yaml
# Get Pod Name from Kafka
# Get IP from secret
# Configure local /etc/hosts (for KafkaTool)
# Configure 4 and 6 with
#
#      hostAliases:
#        - ip: 10.111.143.18
#          hostnames:
#            - kafka-8587c7c85c-b7pqr
#
kubectl apply -f 4\ -\ Kafka\ Manager.yaml
kubectl apply -f 5\ -\ SourceConnector.yaml
kubectl apply -f 6\ -\ Cp\ KafkaConnect.yaml
