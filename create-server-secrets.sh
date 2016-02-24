#!/bin/ash
# Create SERVER secrets

# Read comandline paramenter and set variables
vpn_host=$1

# Create certificate authority
ipsec pki --gen --outform pem > caKey.pem
ipsec pki --self --in caKey.pem --dn "C=DE, O=strongSwan, CN=strongSwan Root CA" --ca --outform pem > caCert.pem

# Create server key and certificate
ipsec pki --gen --outform pem > serverKey.pem
ipsec pki --pub --in serverKey.pem | ipsec pki --issue --cacert caCert.pem --cakey caKey.pem --dn "C=DE, O=strongSwan, CN=${vpn_host}" --san="${vpn_host}" --flag serverAuth --flag ikeIntermediate --outform pem > serverCert.pem

# Move secrets to respective directories
mv caCert.pem /etc/ipsec.d/cacerts/
mv caKey.pem /etc/ipsec.d/private/
mv serverCert.pem /etc/ipsec.d/certs/
mv serverKey.pem /etc/ipsec.d/private/

# some how '$ ipsec rereadall' does not do the job, let's go aggressive
ipsec restart
