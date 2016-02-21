# VPN server for the ARM based Raspberry PI

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
             --name vpnserver \
             --restart unless-stopped \
             --volume /secrets:/etc/ipsec.d/private \
             -p 500:500/udp \
             -p 4500:4500/udp \
             --privileged netzfisch/rpi-vpn-server
```

#### Create Server secretes

First create the **server secrets**, therefore **go into the running container**

```sh
$ docker exec -it vpnserver /bin/ash
/ export HOST=your-subdomain.spdns.de
/ ./create-server-secrets.sh
/ exit
```

#### Create User secrets

Than create the **user secrets**

```sh
$ docker exec -it vpnserver /bin/ash
/ export USER=DemoUser
/ export PASSPHRASE=SuperUnknown
/ ./create-user-secrets.sh
/ ipsec reload
/ exit
```

In your locally mapped `/secrets` directory you will find the **encrypted
PKCS#12 archive clientCert.p12**, which you need to import to your remote VPN
client e.g.
[strongSwan](https://play.google.com/store/apps/details?id=org.strongswan.android).
For **verification** and to unlock this archive you will be asked for above
**PASSPHRASE**, so better remember!

## Debugging

If you have trouble, **check on the running container**:

* First look at the **logs** `$ docker logs -f vpnserver`,
* get the **ipsec status** `$ docker exec vpnserver ipsec statusall` or
* **go into** for further investigation `$ docker exec -it vpnserver ash`, than
  iterate through
  * `$ vi /etc/ipsec.conf`
  * `$ ipesc reload`
  * `$ ipsec status`

until you found a working configuration, see **strongSwan**
[documentation](https://wiki.strongswan.org/projects/strongswan/wiki/IntroductionTostrongSwan)
and [configuration
examples](https://wiki.strongswan.org/projects/strongswan/wiki/IKEv2Examples)!

If all not helps, export the whole container `$ docker export vpnserver > vpn-server.tar`
and examine the file system.

## Contributing

If you find a problem, please create a
[GitHub Issue](https://github.com/netzfisch/rpi-tvheadend/issues).

Have a fix, want to add or request a feature?
[Pull Requests](https://github.com/netzfisch/rpi-tvheadend/pulls) are welcome!

### TODOs

- [ ] Consist naming of credentials/certificates/keys/secrets etc.
- [ ] Enable adding multiple users by personalising clientCert.pem
- [ ] Add initial USER with random generated PASSPHRASE if not provided
- [ ] Add nginx container to Serve ClientCert.p12
- [ ] Add container for dynamic DNS updates

### License

The MIT License (MIT), see [LICENSE](LICENSE) file.
