#!/bin/bash

set -eu -o pipefail

#openssl req -new -text -passout pass:abcd -subj /CN=localhost -out server.req
#openssl rsa -in privkey.pem -passin pass:abcd -out server.key
#openssl req -x509 -in server.req -text -key server.key -out server.crt
#chown 999 cert-key.pem
#chmod 600 cert-key.pem


#docker network create --driver bridge postgrix
docker run --rm --name internal_db --network postgrix -p 5432:5432 -e POSTGRES_USER=ps_internal -e POSTGRES_PASSWORD=mysecretpassword1 -e POSTGRES_DB=internal_db -d postgres:9.6 -c logging_collector=on
docker run --rm --name postgres_cluster --network postgrix -p 5433:5432 -e POSTGRES_USER=postgres -e POSTGRES_PASSWORD=mysecretpassword2 -e POSTGRES_DB=postgres_cluster -d -v $PWD/cert.pem:/var/lib/postgresql/server.crt -v $PWD/cert-key.pem:/var/lib/postgresql/server.key postgres:9.6 -c logging_collector=on -c ssl=on -c ssl_cert_file=/var/lib/postgresql/server.crt -c ssl_key_file=/var/lib/postgresql/server.key
docker run --rm --name vault --network postgrix -p 8200:8200 --cap-add=IPC_LOCK -e 'VAULT_DEV_ROOT_TOKEN_ID=myroot' -e 'VAULT_DEV_LISTEN_ADDRESS=0.0.0.0:8200' -e 'VAULT_ADDR=http://127.0.0.1:8200' -d vault
docker exec -ti my_container sh -c "vault login token=myroot && vault audit enable file file_path=/vault/logs/vault_audit.log && vault secrets enable database"