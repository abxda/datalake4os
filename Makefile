hive_image = datalake4os/hive:3.1.0

.PHONY: build create-docker-network persistence-up sleep10 minio-provision metastore-up hive-server-up \
	metastore-create-table presto-up presto-query-example up down

build:
	docker build -f services/hive/hive.dockerfile  -t ${hive_image} ./services/hive
create-docker-network:
	docker network create -d bridge datalake4os-net || docker network ls | grep datalake4os-net
persistence-up:
	docker-compose up -d minio database
sleep10:
	sleep 10
sleep20:
	sleep 20
minio-provision:
	docker-compose -f services/minio/docker-compose.s3-provision.yml up
metastore-up:
	docker-compose up -d hive-metastore
hive-server-up:
	docker-compose up -d hive-server
metastore-create-table:
	docker-compose exec hive-metastore beeline -u jdbc:hive2:// -f /tmp/create-table.hql
presto-up:
	docker-compose up -d presto
presto-query-example:
	docker-compose exec presto presto -f /tmp/query-example.sql

up: build create-docker-network persistence-up sleep10 minio-provision metastore-up \
	hive-server-up presto-up sleep20 metastore-create-table presto-query-example
down:
	docker-compose -f services/minio/docker-compose.s3-provision.yml down
	docker-compose down
	docker network rm datalake4os-net