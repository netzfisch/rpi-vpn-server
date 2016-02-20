FROM hypriot/rpi-alpine-scratch
MAINTAINER netzfisch

# TODO move to seperate env-file or document overwriting at the commandline
# The password is later on replaced with a random string
ENV VPN_HOST XXXXX.spdns.de
ENV VPN_USER user
ENV VPN_PASSWORD password
ENV KEY_PASSPHRASE key_passphrase

# Install strongswan, dependent packackes and clean up
RUN apk add --update strongswan \
 && rm -rf /var/cache/apk/*

# Configure ipsec, etc. 
COPY ipsec.conf /etc/ipsec.conf
#COPY ipsec.secrets /etc/ipsec.secrets
RUN echo ": RSA serverKey.pem"                  > /etc/ipsec.secrets
RUN echo "$VPN_USER : EAP \"$VPN_PASSWORD\""   >> /etc/ipsec.secrets
RUN echo "$VPN_USER : XAUTH \"$VPN_PASSWORD\"" >> /etc/ipsec.secrets
COPY sysctl.conf /etc/syctl.conf

# TODO move to create_secrets.sh
# Create set of keys and certificates
RUN ipsec pki --gen --outform pem > caKey.pem \
 && ipsec pki --self --in caKey.pem --dn "C=DE, O=strongSwan, CN=strongSwan Root CA" --ca --outform pem > caCert.pem \
 && ipsec pki --gen --outform pem > serverKey.pem \
 && ipsec pki --pub --in serverKey.pem | ipsec pki --issue --cacert caCert.pem --cakey caKey.pem --dn "C=DE, O=strongSwan, CN=$VPN_HOST" --san="$VPN_HOST" --flag serverAuth --flag ikeIntermediate --outform pem > serverCert.pem \
 && ipsec pki --gen --outform pem > clientKey.pem \
 && ipsec pki --pub --in clientKey.pem | ipsec pki --issue --cacert caCert.pem --cakey caKey.pem --dn "C=DE, O=strongSwan, CN=$VPN_USER" --outform pem > clientCert.pem \
 && openssl pkcs12 -export -password "pass:$KEY_PASSPHRASE" -inkey clientKey.pem -in clientCert.pem -name "$VPN_USER" -certfile caCert.pem -caname "strongSwan Root CA" -out clientCert.p12

# Move keys to respective directories
RUN mv caCert.pem /etc/ipsec.d/cacerts/ \
 && mv caKey.pem /etc/ipsec.d/private/ \
 && mv serverCert.pem /etc/ipsec.d/certs/ \
 && mv serverKey.pem /etc/ipsec.d/private/ \
 && mv clientCert.pem /etc/ipsec.d/certs/ \
 && mv clientKey.pem /etc/ipsec.d/private/ \
 && mv clientCert.p12 /etc/ipsec.d/private/

# Persist keys
VOLUME /etc/ipsec.d

# Expose ipsec ports
EXPOSE 500/udp 4500/udp

CMD ipsec start --nofork
