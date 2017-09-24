FROM hypriot/rpi-alpine:3.6
MAINTAINER netzfisch

# MAKE SURE to set appropriate configuration variables via option flags
# '$ docker run --env ...'. If VPN_USER is not set, see README for manual
# "import" or "setup" of secrets!
ENV VPN_USER=''

# Install strongswan packackes and clean up
RUN apk add --update openssl strongswan \
  && rm -rf /var/cache/apk/*

# Copy ipsec, iptable configuration
COPY ipsec.conf /etc/
COPY local.conf /etc/sysctl.d/

# Create scripts to manage VPN service
COPY init setup secrets /usr/local/bin/
RUN chmod +x /usr/local/bin/*

# Enable access of secrets
VOLUME /mnt

# Expose ipsec ports
EXPOSE 500/udp 4500/udp

# Start VPN service
ENTRYPOINT ["/usr/local/bin/init"]
