#!/bin/ash
# Create USER secrets

# Read comandline paramenters and set variables
user=$1
password=$2

# Create client key and certificate
ipsec pki --gen --outform pem > clientKey.pem
ipsec pki --pub --in clientKey.pem | ipsec pki --issue --cacert /etc/ipsec.d/cacerts/caCert.pem --cakey /etc/ipsec.d/private/caKey.pem --dn "C=DE, O=strongSwan, CN=${user}" --outform pem > clientCert.pem

# Create encrypted PKCS#12 archive for client
openssl pkcs12 -export -password "pass:${password}" -inkey clientKey.pem -in clientCert.pem -name "${user}" -certfile /etc/ipsec.d/cacerts/caCert.pem -caname "strongSwan Root CA" -out clientCert.p12

# Move secrets to respective directories
mv clientCert.pem /etc/ipsec.d/certs/
mv clientKey.pem /etc/ipsec.d/private/
mv clientCert.p12 /mnt/

# some how '$ ipsec rereadall' does not do the job, let's go aggressive
ipsec restart
