#!/bin/sh

# enter the CN
# TODO: cli input

CN="dev.awzm.sh"
ORG="awzm.sh"

# generate CA
openssl req -x509 -sha256 -newkey rsa:4096 -keyout ca.key -out ca.crt -days 365 -nodes -subj "/CN=${CN}"

# generate client CSR
openssl req -new -newkey rsa:4096 -keyout client.key -out client.csr -nodes -subj "/C=DE/ST=Berlin/L=Berlin/O=${ORG}/CN=${CN}"

# sign CSR with CA
openssl x509 -req -sha256 -days 365 -in client.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out client.crt -copy_extensions=copyall

# verify client.crt
openssl verify -verbose -CAfile ca.crt client.crt
