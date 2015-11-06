#!/bin/sh

if [ $# -ne 2 ]
then
	echo "Usage: $0 shortname IP"
	exit 1
fi

cat << EOF > /etc/pki/tls/$1-req.conf
[req]
default_bits		= 2048
default_md		= sha256
default_keyfile		= /etc/pki/tls/private/$1.key
distinguished_name	= req_distinguished_name
# attributes		= req_attributes
req_extensions		= v3_req

[req_distinguished_name]
commonName		= $1.domain.org
#commonName		= $1.domain.com
# ...
# countryName		= US

[v3_req]
keyUsage		= critical, digitalSignature, keyEncipherment
subjectAltName		= @alt_names

[alt_names]
IP.1			= $2
DNS.1			= $1.domain.org
#DNS.1			= $1.domain.com
DNS.2			= $1
#DNS.3			= somealias.domain.com
#DNS.4			= somealias
EOF

openssl req -newkey rsa:2048 -nodes -subj "/C=US/ST=XXXXXXX/L=XXXXXX/O=XXXX/OU=XXX/CN=$1.domain.org/" -days 1095 -sha256 -config /etc/pki/tls/$1-req.conf | tee /etc/pki/tls/certs/$1.csr
#openssl req -newkey rsa:2048 -nodes -subj "/C=US/ST=XXXXXXX/L=XXXXXXX/O=XXXX/OU=XXXXX/CN=$1.domain.com/" -days 1095 -sha256 -config /etc/pki/tls/$1-req.conf | tee /etc/pki/tls/certs/$1.csr
