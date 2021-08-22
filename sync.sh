#!/bin/bash

# check for keytool is installed
keytool=$(which keytool)

# check if sslmate is installed
if [ ! -x /usr/bin/sslmate ]; then
    echo "Missing sslmate package"
    exit 1
fi

if [ -n "$SSLMATE_API_KEY_FILE" ]; then
  echo "Attemping to use sslmate api key secret"
  if [ -f "$SSLMATE_API_KEY_FILE" ]; then
    echo "Secret found. Setting as SSLMATE_API_KEY"
    SSLMATE_API_KEY="$(< "$SSLMATE_API_KEY_FILE")"
  fi
fi

if [[ -z "$SSLMATE_API_KEY" ]]; then
   echo "Missing sslmate api key from environment. Variable name must be SSLMATE_API_KEY"
   exit 1
fi

if [ ! -d /etc/sslmate/keys ]; then
    mkdir -p /etc/sslmate/keys
fi

if [ ! -d /etc/sslmate/certs ]; then
    mkdir -p /etc/sslmate/certs
fi

# COPY secret keys to keys dir
# NOTE: /etc/sslmate needs to be a named volume so key is not stored in image
for FILE in /run/secrets/*DOMAIN_*; do
  FNAME=${FILE##*_}
  FNAME=${FNAME,,}
  cp "${FILE}" "/etc/sslmate/keys/${FNAME}" 
done

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
  # Download
  echo \
  "$(date): Attemping to download..."
  if sslmate download --all; then
    echo "$(date) Downloaded new certificates! Touch NEW in 'keys' directory"
    touch /etc/sslmate/certs/NEW
  else
    if [[ "$?" != "10" ]]; then
      echo "sslmate error"
      exit
    fi
  fi

  # Sleep
  modulus=4
  for expiration in $(sslmate list -z --columns=expiration); do
    timeleft=$(( expiration - $(date +"%s") ))
    echo -n "timeleft: $timeleft "
    if (( timeleft <= 0 )); then
      r=$((RANDOM%modulus))
      if [[ -v $sleeptime ]]; then
        sleeptime=$(( sleeptime > r ? r : sleeptime ))
      else
        sleeptime=$r
      fi
      modulus=$(( modulus*2 ))
      modulus=$(( modulus > 32768 ? 256 : modulus ))
    else
      r=$((timeleft*9/10))
      if [[ -v $sleeptime ]]; then
        sleeptime=$(( sleeptime > r ? r : sleeptime ))
      else
        sleeptime=$r
      fi
      modulus=4
    fi
  done
  echo "- sleeping for $sleeptime seconds"
  sleep $sleeptime
done

exit 0
