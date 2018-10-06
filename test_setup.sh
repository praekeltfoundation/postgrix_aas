#!/bin/bash

docker run --rm --name internal_db -p 5432:5432 -e POSTGRES_USER=ps_internal -e POSTGRES_PASSWORD=mysecretpassword1 -e POSTGRES_DB=internal_db -d postgres:9.6 -c logging_collector=on
docker run --rm --name postgres_cluster -p 5433:5432 -e POSTGRES_PASSWORD=mysecretpassword2 -e POSTGRES_DB=postgres_cluster -d postgres:9.6 -c logging_collector=on
docker run --rm --name vault -p 8200:8200 --cap-add=IPC_LOCK -e 'VAULT_DEV_ROOT_TOKEN_ID=myroot' -e 'VAULT_DEV_LISTEN_ADDRESS=0.0.0.0:8200' -d vault