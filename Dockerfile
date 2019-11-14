FROM confluentinc/cp-kafka-connect:5.3.1

ENV CONNECT_PLUGIN_PATH="/usr/share/java,/usr/share/confluent-hub-components"

RUN mkdir -p /usr/share/confluent-hub-components/kafka-connect-mongodb

ADD https://repo1.maven.org/maven2/org/mongodb/kafka/mongo-kafka-connect/0.2/mongo-kafka-connect-0.2-all.jar /usr/share/confluent-hub-components/kafka-connect-mongodb/

RUN  confluent-hub install --no-prompt confluentinc/kafka-connect-datagen:latest
