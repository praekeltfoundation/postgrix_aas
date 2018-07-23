#!/bin/bash

docker run --rm --name internal_db -p 5432:5432 -e POSTGRES_USER=ps_internal -e POSTGRES_PASSWORD=mysecretpassword1 -e POSTGRES_DB=internal_db -d postgres -c logging_collector=on
docker run --rm --name postgres_cluster -p 5433:5432 -e POSTGRES_PASSWORD=mysecretpassword2 -e POSTGRES_DB=postgres_cluster -d postgres -c logging_collector=on