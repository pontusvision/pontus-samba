#!/bin/bash

export tls_home=${tls_home:-/etc/pki}
export tls_rootca_passphrase=${tls_rootca_passphrase:-pa55word}
export privkey_passphrase=${privkey_passphrase:-pa55word}
export truststore_pass=${truststore_pass:-changeit}
export truststore_type=${truststore_type:-JKS}
yum  install -y java-1.8.0-openjdk-devel

mkdir -p ${tls_home}/private ${tls_home}/java

cat << 'EOF2' >> ${tls_home}/private/root-ca.cnf
[root_ca]
basicConstraints = critical,CA:TRUE,pathlen:1
keyUsage = critical, nonRepudiation, cRLSign, keyCertSign
subjectKeyIdentifier=hash
EOF2

openssl genrsa -out "${tls_home}/private/root-ca.pem" 4096 -passin "pass:${tls_rootca_passphrase}"

openssl req -new -key "${tls_home}/private/root-ca.pem" -out "${tls_home}/private/root-ca.csr" -sha256 -subj '/C=UK/ST=London/L=London/O=PontusVision/OU=GDPR/CN=CA'

openssl x509 -req  -days 3650  -in "${tls_home}/private/root-ca.csr" -signkey "${tls_home}/private/root-ca.pem" -sha256 -out "${tls_home}/private/root-ca.crt" -extfile "${tls_home}/private/root-ca.cnf" -extensions root_ca

keytool -keystore "${tls_home}/java/truststore.jks" -alias CARoot -import -file "${tls_home}/private/root-ca.crt" -storetype "${truststore_type}" -storepass "${truststore_pass}" -noprompt

openssl genrsa -out "${tls_home}/private/localhost.pem" 4096 -passin "pass:${privkey_passphrase}"

cat << 'EOF2' >> ${tls_home}/private/localhost.cnf
[server]
authorityKeyIdentifier=keyid,issuer
basicConstraints = critical,CA:FALSE
extendedKeyUsage=serverAuth,clientAuth
keyUsage = critical, digitalSignature, keyEncipherment
subjectAltName = DNS:localhost, IP:127.0.0.1
subjectKeyIdentifier=hash
EOF2

openssl req -new -key "${tls_home}/private/localhost.pem" -out "${tls_home}/private/localhost.csr" -sha256 -subj "/C=UK/ST=London/L=London/O=PontusVision/OU=GDPR/CN=localhost"

openssl x509 -req -days 750 -passin "pass:${tls_rootca_passphrase}" -in "${tls_home}/private/localhost.csr" -sha256 -CA "${tls_home}/private/root-ca.crt" -CAkey "${tls_home}/private/root-ca.pem"  -CAcreateserial -out "${tls_home}/private/localhost.crt" -extfile "${tls_home}/private/localhost.cnf" -extensions server

openssl pkcs12 -export -in "${tls_home}/private/localhost.crt" -inkey "${tls_home}/private/localhost.pem" -out  "${tls_home}/private/localhost.p12" -name "localhost" -password "pass:${privkey_passphrase}"

keytool -importkeystore -srckeystore "${tls_home}/private/localhost.p12" -destkeystore "${tls_home}/private/localhost.jks" -srcstorepass "${privkey_passphrase}" -deststorepass "${privkey_passphrase}"
openssl pkcs8 -in ${tls_home}/private/localhost.pem -topk8 -nocrypt -out ${tls_home}/private/localhost.pem.pk8

cp ${tls_home}/private/* ${tls_home}/java/

cp ${tls_home}/java/localhost.jks ${tls_home}/java/keystore.jks

