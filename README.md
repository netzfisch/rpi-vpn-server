# VPN server Image for the Raspberry PI

Turn your [Raspberry PI](http://raspberrypi.org) within **15 minutes** into a
**VPN server** allowing **remote access** and **tunneling traffic** through your
trusted home network!

This **images aims at ARM architecture**, uses the well known [stronSwan
IPsec](https://www.strongswan.org/) stack, is based on
[alpine Linux](http://www.alpinelinux.org/), which is with ~5 MB much smaller
than most other distribution base, and thus leads to a **slimmer VPN server
image**.

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
             --volume /secrets:/mnt \
             --cap-add NET_ADMIN \
             -p 500:500/udp \
             -p 4500:4500/udp \
             netzfisch/rpi-vpn-server
```

#### Setup Server

First setup the VPN server by defining the **gateway URL**, which will create
the approbiate **server secrets**

```sh
$ docker exec vpnserver setup.sh your-subdomain.spdns.de
```

#### Create User

Than create the **user secrets**

```sh
$ docker exec vpnserver setup.sh user VpnUser SecretPassword
```

You will find in your locally mapped `/secrets` directory the **encrypted
PKCS#12 archive clientCert.p12**, which you need to import at your remote VPN
client and will be unlocked by the **SecretPassword**, e.g. use on Android
[strongSwan](https://play.google.com/store/apps/details?id=org.strongswan.android).
The **password**  will be also used for **XAUTH scenarios**, so better remember!

#### Manage secrets

To **export** do `$ docker exec vpnserver secrets.sh export`
than you will find the set of secrets in the mounted volume `/secrets`.

To **import** put your set of secrets into the mounted volume `/secrets` and
execute `$ docker exec vpnserver secrets.sh import`.

## Debugging

If you have trouble, **check on the running container**:

* First look at the **logs** `$ docker logs -f vpnserver`,
* get the **ipsec status** `$ docker exec vpnserver ipsec statusall` or
* **go into** for further investigation `$ docker exec -it vpnserver ash`, than
  iterate through
  * `$ vi /etc/ipsec.conf`
  * `$ ipesc reload`
  * `$ ipsec status`
  * `$ routel`
  * `$ iptables -t nat -L`

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
