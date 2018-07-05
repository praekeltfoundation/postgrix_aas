#!/bin/bash

docker run --rm --name internal_db -p 5432:5432 -e POSTGRES_PASSWORD=mysecretpassword1 -e POSTGRES_DB=internal_db -d postgres
docker run --rm --name postgres_cluster -p 5433:5432 -e POSTGRES_PASSWORD=mysecretpassword2 -e POSTGRES_DB=postgres_cluster -d postgres