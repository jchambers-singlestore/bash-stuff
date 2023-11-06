#!/bin/bash

# Can use the following to test SSL Ciphers with mysql
#Syntax: ./TestSSLCiphers.sh <hostname> <port>

TEST_SERVER=${1}
TEST_PORT=${2}

for v in tls1_1 tls1_2; do
for c in $(openssl ciphers 'ALL:eNULL' | tr ':' ' '); do
openssl s_client -starttls mysql -connect ${TEST_SERVER}:${TEST_PORT} \
-cipher $c -$v < /dev/null > /dev/null 2>&1 && echo -e "$v:\t$c"
done
done

# Use the following if you want to test the https_proxy_port on SingleStoreDB

##!/bin/bash
#TEST_SERVER=${1}
#TEST_PORT=${2}

#for v in tls1_1 tls1_2; do
#for c in $(openssl ciphers 'ALL:eNULL' | tr ':' ' '); do
#openssl s_client -connect ${TEST_SERVER}:${TEST_PORT} \
#-cipher $c -$v < /dev/null > /dev/null 2>&1 && echo -e "$v:\t$c"
#done
#done
