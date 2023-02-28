cd /tmp/kafka_2.13-3.4.0

#Consume topic
bin/kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic shareplex --from-beginning

cd -
