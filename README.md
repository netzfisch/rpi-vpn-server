# VPN-Server for Raspberry PI as docker image

Turn your [Raspberry PI](http://raspberrypi.org) within **15 minutes** into a
**VPN server** allowing remote access and tunneling traffic through your
trusted home network.

This repository defines a **docker image for the ARM architecture**, based on
[alpine Linux](http://www.alpinelinux.org/), which is with ~5 MB much smaller
than most other distribution base images, and thus leads to a **slimmer vpn
server image**:

[![](https://badge.imagelayers.io/netzfisch/rpi-vpn-server:latest.svg)](https://imagelayers.io/?images=netzfisch/rpi-vpn-server:latest)

Find the source code at [GitHub](https://github.com/netzfisch/rpi-vpn-server) or
the ready-to-run image in the
[DockerHub](https://hub.docker.com/r/netzfisch/rpi-vpn-server/) and **do not
forget to _star_** the repository ;-)

## Requirements

- [Raspberry PI](http://raspberrypi.org)
- [Docker Engine](https://docs.docker.com/engine/quickstart/)
- Dynamic DNS service provider, e.g. from [Securepoint](https://www.spdns.de/)

### Setup

- Install HypriotOS, which is based on Raspbian a debian derivate and results to
a working docker host, see
[Getting Started](http://blog.hypriot.com/getting-started-with-docker-and-linux-on-the-raspberry-pi/) !
- Change your network interface to a static IP

```sh
$ cat > /etc/network/interfaces << EOF
  allow-hotplug eth0
  iface eth0 inet static
    address 192.168.PI.IP
    netmask 255.255.255.0
    gateway 192.168.XXX.XXX
EOF
```

- Configure in your router the **dynamic DNS updates** of your domain
- Enable **port forwarding** at your firewall for 192.168.PI.IP and the UDP
ports 500 and 4500
- **Pull** the respective **docker image** `$ docker pull netzfisch/rpi-vpn-server`

### Usage

Get ready to roll and run the container:

```sh
$ docker run --detach \
             --name vpn-server \
             --restart unless-stopped \
             -p 500:500/udp \
             -p 4500:4500/ udp \
             --env VPN_USER=user \
             --env VPN_PASSWORD=password \
             --env KEY_PASSPHRASE=passphrase \
             --volume /secrets:/etc/ipsec.d/private \
             --privileged netzfisch/rpi-tvheadend
```

Find the **key for remote access** clientCert.p12 in the local directory
`/secrets`, which you need to import to your VPN client for remote access, e.g.
[strongSwan](https://play.google.com/store/apps/details?id=org.strongswan.android)

#### Add more users

To create more users for remote access you have to **go into the container**

```sh
$ docker exec -it vpn-server /bin/ash
/ export VPN_USER=user2
/ export VPN_PASSWORD=SecretPassword
/ export KEY_PASSPHRASE=SuperUnknown
/ make-user-credentials.sh
/ ipsec reload
/ exit
```

Find the **key for remote access** again in the local directory `/secrets`.

## Debugging

If you have trouble, **check on the running container**:

* First look at the **logs** `$ docker logs -f vpnserver`,
* get the **ipsec status** `$ docker exec vpnserver ipsec statusall` or
* **go into** for further investigation `$ docker exec -it vpnserver ash`, than
  iterate through
  * `$ vi /etc/ipsec.conf`
  * `$ ipesc reload`
  * `$ ipsec status`
  until you found a working configuration!

If all not helps, export the whole container `$ docker export vpnserver > vpn-server.tar`
and examine the file system.

## Contributing

If you find a problem, please create a
[GitHub Issue](https://github.com/netzfisch/rpi-tvheadend/issues).

Have a fix, want to add or request a feature?
[Pull Requests](https://github.com/netzfisch/rpi-tvheadend/pulls) are welcome!

### TODOs

- [ ] Consist naming of credentials/certificats/keys etc.
- [ ] Add/ remove of users/keys interactively
- [ ] Add nginx container to Serve ClientCert.p12
- [ ] Add container for dynamic DNS updates

### License

The MIT License (MIT), see [LICENSE](LICENSE) file.
