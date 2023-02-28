cd /tmp/kafka_2.13-3.4.0

#Produce topic
echo "test local machine"  | bin/kafka-console-producer.sh --broker-list localhost:9092 --topic test

cd -
