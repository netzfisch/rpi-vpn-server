FROM hypriot/rpi-alpine-scratch
MAINTAINER netzfisch

# Install strongswan packackes and clean up
RUN apk add --update strongswan && \
    rm -rf /var/cache/apk/*

# Configure ipsec, iptable
COPY ipsec.conf /etc/
COPY ipsec.secrets /etc/
COPY local.conf /etc/sysctl.d/

# Copy scripts for creating and managing secrets
COPY create-server-secrets.sh /usr/local/bin/
COPY create-user-secrets.sh /usr/local/bin/
COPY vpn-secrets.sh /usr/local/bin/

# Enable access of secrets
VOLUME /mnt

# Expose ipsec ports
EXPOSE 500/udp 4500/udp

# Start VPN service
CMD ipsec start --nofork
