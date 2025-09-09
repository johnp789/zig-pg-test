#!/usr/bin/env bash

docker run --rm -v $(pwd)/certs:/certs alpine:latest sh -c "
    apk add --no-cache openssl && \
    openssl genrsa -out /certs/ca.key 4096 && \
    openssl req -x509 -new -nodes -key /certs/ca.key -sha256 -days 3650 -out /certs/ca.crt -subj '/CN=Postgres Root CA' && \
    openssl genrsa -out /certs/server.key 4096 && \
    chmod 600 /certs/server.key && \
    openssl req -new -key /certs/server.key -out /certs/server.csr -subj '/CN=db' && \
    openssl x509 -req -in /certs/server.csr -CA /certs/ca.crt -CAkey /certs/ca.key -CAcreateserial -out /certs/server.crt -days 365 -sha256
"
