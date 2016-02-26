#!/bin/ash
# Setup VPN server

# Exit with "1" by failure
set -e

# Setup NAT forwarding if not already set, see '$ iptables -t nat -L'
iptables --table nat --check POSTROUTING --jump MASQUERADE || {
  iptables --table nat --append POSTROUTING --jump MASQUERADE
}

case "$1" in
  setup)
    # Assign variable
    vpnhost=$2

    # CA certificate (Authority)
    ipsec pki --gen --outform pem > caKey.pem
    ipsec pki --self --in caKey.pem --dn "C=DE, O=strongSwan, CN=strongSwan Root CA" --ca --outform pem > caCert.pem

    # VPN server certificate (Gateway)
    ipsec pki --gen --outform pem > serverKey.pem
    ipsec pki --pub --in serverKey.pem | ipsec pki --issue --cacert caCert.pem --cakey caKey.pem \
              --dn "C=DE, O=strongSwan, CN=${vpnhost}" --san="${vpnhost}" \
              --flag serverAuth --flag ikeIntermediate --outform pem > serverCert.pem

    # Move secrets to respective directories
    mv caCert.pem /etc/ipsec.d/cacerts/
    mv serverCert.pem /etc/ipsec.d/certs/
    mv caKey.pem serverKey.pem /etc/ipsec.d/private/
    ;;
  user)
    # Assign variables
    user=$2
    password=$3

    # Create client key and certificate
    ipsec pki --gen --outform pem > clientKey.pem
    ipsec pki --pub --in clientKey.pem | \
      ipsec pki --issue --cacert /etc/ipsec.d/cacerts/caCert.pem --cakey /etc/ipsec.d/private/caKey.pem \
                --dn "C=DE, O=strongSwan, CN=${user}" --outform pem > clientCert.pem

    # Create encrypted PKCS#12 archive for client
    openssl pkcs12 -export -password "pass:${password}" -inkey clientKey.pem -in clientCert.pem -name "${user}" \
                   -certfile /etc/ipsec.d/cacerts/caCert.pem -caname "strongSwan Root CA" -out clientCert.p12

    # Move secrets to respective directories
    mv clientCert.pem /etc/ipsec.d/certs/
    mv clientKey.pem /etc/ipsec.d/private/
    mv clientCert.p12 /mnt/

    echo "${user} : XAUTH "${password}"" >> /etc/ipsec.secrets
    ;;
esac

# ReRead all credentials
ipsec rereadall && ipsec reload
