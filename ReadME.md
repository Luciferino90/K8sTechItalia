1 - Download Apache Spark sources from https://spark.apache.org/downloads.html
2 - Replace spark-2.4.4-bin-hadoop2.7/kubernetes/dockerfiles/spark/Dockerfile with CustomDockerfiles/Spark (this step will overwrite kubernetes-client-4.1.2.jar with kubernetes-client-4.4.2.jar)
3 - Build spark docker image by goingo into APACHE_SPARK_HOME_DIR (spark-2.4.4-bin-hadoop2.7) and launch docker build -f kubernetes/dockerfiles/spark/Dockerfile .
4 - Put this image to a remote docker repository, even the one inside K8s
5 - Use this spark image to build your own spark application
6 - Download Zeppelin sources from https://github.com/apache/zeppelin
7 - Create an empty folder and move zeppelin-0.9.0-SNAPSHOT folder, CustomDockerfiles/Zeppelin logging/log4j.properties and yaml/ZeppelinInterpreter/100-interpreter-spec.yaml
8 - Launch mvn clean package inside zeppelin-0.9.0-SNAPSHOT. Until apache-spark-3.0.0 please use Java JDK 1.8
9 - Use custom Dockerfile to build a working zeppelin docker image
10 - Put this image to a remote docker repository, even the one inside K8s
11 - Download mongo-kafka-0.2-all.jar from https://www.confluent.io/hub/mongodb/kafka-connect-mongodb
12 - Use CustomDockerfiles/KafkaConnect to build a kafka connect docker image with mongodb driver
13 - Put this image to a remote docker repository, even the one inside K8s
14 - Install helm
15 - Launch helm init
16 - Open BashScript/Installer.sh and configure starting args (beware of 100-interpreter-spec.yaml for mounted path)
17 - Launch sh BashScript/Installer.sh
18 - Launch uninstaller to destroy the namespace completely sh BashScript/Uninstaller.sh <namespace>