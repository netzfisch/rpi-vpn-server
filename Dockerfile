FROM hypriot/alpine:3.6
MAINTAINER netzfisch

# MAKE SURE to set appropriate configuration variables via option flags
# '$ docker run --env ...' or via scripts '$ docker exec vpnserver setup ...',
# if not set - at least a random password will be assigned!
ENV VPN_HOST demo.example.com
ENV VPN_USER user
ENV VPN_PASSWORD none

# Install strongswan packackes and clean up
RUN apk add --update strongswan && \
    rm -rf /var/cache/apk/*

# Copy ipsec, iptable configuration
COPY ipsec.conf /etc/
COPY local.conf /etc/sysctl.d/

# Create scripts to manage VPN service
COPY init setup secrets /usr/local/bin/
ENV PATH /usr/local/bin:$PATH
RUN chmod +x /usr/local/bin/*

# Enable access of secrets
VOLUME /mnt

# Expose ipsec ports
EXPOSE 500/udp 4500/udp

# Start VPN service
ENTRYPOINT ["/usr/local/bin/init"]
