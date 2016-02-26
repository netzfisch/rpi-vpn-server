FROM hypriot/rpi-alpine-scratch
MAINTAINER netzfisch

# Install strongswan packackes and clean up
RUN apk add --update strongswan && \
    rm -rf /var/cache/apk/*

# Copy ipsec, iptable configuration
COPY ipsec.conf /etc/
COPY ipsec.secrets /etc/
COPY local.conf /etc/sysctl.d/

# Create scripts for managing the service
COPY setup.sh secrets.sh /usr/local/bin/
ENV PATH /usr/local/bin:$PATH
RUN chmod +x /usr/local/bin/*.sh

# Enable access of secrets
VOLUME /mnt

# Expose ipsec ports
EXPOSE 500/udp 4500/udp

# Start VPN service
CMD ["ipsec","start","--nofork"]
