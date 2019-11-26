#!/bin/sh
cd /Users/luca/workbench/techitalia/Java/sparkstream


docker build -t tech-spark:latest --build-arg JAR_FILE=mongo-spark-streaming-launch.jar --build-arg JAR_VERSION=0.0.1 --build-arg START_CLASS=it.arubapec.esecurity.mongostreamspark.SpringKafkaApplication .
docker tag tech-spark:latest localhost:5000/tech-spark:latest
docker push localhost:5000/tech-spark:latest

cd $SPARK_HOME
bin/spark-submit \
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
