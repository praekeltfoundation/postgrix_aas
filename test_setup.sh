#!/bin/bash

set -eu -o pipefail

docker-compose up -d
docker exec -ti vault sh -c "vault login token=myroot && vault audit enable file file_path=/vault/logs/vault_audit.log && vault secrets enable database"