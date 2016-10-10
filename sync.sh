#!/bin/bash

# check for keytool is installed
keytool=$(which keytool)

# check if sslmate is installed
if [ ! -x /usr/bin/sslmate ]; then
    echo "Missing sslmate package"
    exit 1
fi

if [ "x$SSLMATE_API_KEY" == "x" ]; then
   echo "Missing sslmate api key from environment. Variable name must be SSLMATE_API_KEY"
   exit 1
fi

if [ ! -d /etc/sslmate/keys ]; then
    mkdir -p /etc/sslmate/keys
fi

if [ ! -d /etc/sslmate/certs ]; then
    mkdir -p /etc/sslmate/certs
fi

if [ ! -f /etc/sslmate.conf ]; then
cat > /etc/sslmate.conf <<EOF
api_key ${SSLMATE_API_KEY}
key_directory /etc/sslmate/keys
cert_directory /etc/sslmate/certs
cert_format.chained yes
cert_format.combined yes
cert_format.root yes
cert_format.chain+root yes
wildcard_filename star
key_type rsa
EOF

if [ "$keytool" != "" ]; then
echo "I got keytool"
cat >> /etc/sslmate.conf <<EOF
cert_format.p12 yes
cert_format.jks yes
EOF

else

cat >> /etc/sslmate.conf <<EOF
cert_format.p12 no
cert_format.jks no
EOF

fi

fi

# Sync
while true; do
    sslmate download --all
    sleep 60
done

exit 0
