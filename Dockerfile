FROM hypriot/rpi-alpine-scratch
MAINTAINER netzfisch

# Install strongswan packackes and clean up
RUN apk add --update strongswan && \
    rm -rf /var/cache/apk/*

# Configure ipsec, iptable
COPY ipsec.conf /etc/ipsec.conf
COPY ipsec.secrets /etc/ipsec.secrets
COPY sysctl.conf /etc/syctl.conf

# Copy scripts for creating secrets
COPY create-server-secrets.sh /
COPY create-user-secrets.sh /

# Enable access of secrets
VOLUME /etc/ipsec.d/private

# Expose ipsec ports
EXPOSE 500/udp 4500/udp

# Start VPN service
CMD ipsec start --nofork
