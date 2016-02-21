#!/bin/ash
#
# Create USER secrets

# Create client key and certificate
ipsec pki --gen --outform pem > clientKey.pem
ipsec pki --pub --in clientKey.pem | ipsec pki --issue --cacert /etc/ipsec.d/cacerts/caCert.pem --cakey /etc/ipsec.d/private/caKey.pem --dn "C=DE, O=strongSwan, CN=$USER" --outform pem > clientCert.pem

# Create encrypted PKCS#12 archive for client
openssl pkcs12 -export -password "pass:$PASSPHRASE" -inkey clientKey.pem -in clientCert.pem -name "$USER" -certfile /etc/ipsec.d/cacerts/caCert.pem -caname "strongSwan Root CA" -out clientCert.p12

# Move secrets to respective directories
mv clientCert.pem /etc/ipsec.d/certs/
mv clientKey.pem /etc/ipsec.d/private/
mv clientCert.p12 /etc/ipsec.d/private/

# If ipsec runs - re-read secrets
if [ -f "/var/run/charon.pid" ]; then
  ipsec rereadsecrets
fi
