# VPN Server Image for the Raspberry PI

Turn your [Raspberry PI](http://raspberrypi.org) within **15 minutes** into a **VPN server** allowing **remote access** and **tunneling traffic** through your trusted home network!

This **images aims at ARM architecture**, uses the well known [stronSwan IPsec](https://www.strongswan.org/) stack, is based on [alpine Linux](http://www.alpinelinux.org/), which is with ~5 MB much smaller than most other distribution base, and thus leads to a **slimmer VPN server image**.

[![](https://images.microbadger.com/badges/version/netzfisch/rpi-vpn-server.svg)](https://microbadger.com/images/netzfisch/rpi-vpn-server "Inspect image") [![](https://images.microbadger.com/badges/image/netzfisch/rpi-vpn-server.svg)](https://microbadger.com/images/netzfisch/rpi-vpn-server "Inspect image")

Find the source code at [GitHub](https://github.com/netzfisch/rpi-vpn-server) or the ready-to-run image in the [DockerHub](https://hub.docker.com/r/netzfisch/rpi-vpn-server/) and **do not forget to _star_** the repository ;-)

## Requirements

- [Raspberry PI](http://raspberrypi.org)
- [Docker Engine](https://docs.docker.com/engine/quickstart/)
- Dynamic DNS service provider, e.g. from [Securepoint](https://www.spdns.de/)

### Setup

- **Install a debian Docker package**, which you download [here](http://blog.hypriot.com/downloads/) and install with `dpkg -i package_name.deb`. Alternatively install HypriotOS, which is based on Raspbian a debian derivate and results to a fully working docker host, see [Getting Started](http://blog.hypriot.com/getting-started-with-docker-and-linux-on-the-raspberry-pi/)!
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
- Enable **port forwarding** at your firewall for 192.168.PI.IP and the UDP ports 500 and 4500
- **Pull** the respective **docker image** `$ docker pull netzfisch/rpi-vpn-server`

### Usage

Get ready to roll and run the container:

```sh
$ docker run --detach \
             --env VPN_HOST=your.domain.com \
             --env VPN_USER=yourname \
            (--env VPN_PASSWORD=SecretPassword) \
             --name vpnserver \
             --restart unless-stopped \
             --volume /secrets:/mnt \
             --cap-add NET_ADMIN \
             --net host \
             --publish 500:500/udp \
             --publish 4500:4500/udp \
             netzfisch/rpi-vpn-server
```

If you do **not set** the environment variable **VPN_PASSWORD** a random one will be assigned and shown in the console!

You will find in the locally mapped `/secrets:/mnt` directory the **encrypted PKCS#12 archive clientCert.p12**, which you need to import at your remote VPN client and will be unlocked by the **VPN_PASSWORD**, e.g. use on Android [strongSwan](https://play.google.com/store/apps/details?id=org.strongswan.android). The **VPN_PASSWORD**  will be also used for **XAUTH scenarios**, so better remember!

### Manage

For manual configuration of hostname, user, password, and certificate you have the following options.  

#### Change Certificates

First setup the VPN server by defining the **gateway URL**, which will create the approbiate **server secrets**

```sh
$ docker exec vpnserver setup host your-subdomain.spdns.de
```

#### Change User

Than create the **user secrets**

```sh
$ docker exec vpnserver setup user VpnUser SecretPassword
```

You will find in the locally mapped `/secrets:/mnt` directory the **encrypted PKCS#12 archive clientCert.p12**, which you need to import at your remote VPN client and will be unlocked by the **SecretPassword**, e.g. use on Android [strongSwan](https://play.google.com/store/apps/details?id=org.strongswan.android). The **password**  will be also used for **XAUTH scenarios**, so better remember!

#### Exchange Secrets

To **export** do `$ docker exec vpnserver secrets export` than you will find the set of secrets in the mounted volume `/secrets`.

To **import** put your set of secrets into the mounted volume `/secrets` and execute `$ docker exec vpnserver secrets import`. If you need XAUTH authentication - provide also username and password:

```sh
$ docker exec vpnserver secrets import VpnUser SeecretPassword
```

> **Attention** make sure **not to change naming** of CA-, Cert- and Key-files, otherwise the import  might not work!

#### Configure routing

Finally you need to configure your firewall/router to allow routing to your docker host, do something like

```sh
$ route add -net 10.10.10.0 netmask 255.255.255.0 gw 192.168.PI.IP
```

to send packages for the **remote subnet** `10.10.10.0` to your **docker host** `192.168.PI.IP`!

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

until you found a working configuration, see **strongSwan** [introduction](https://wiki.strongswan.org/projects/strongswan/wiki/IntroductionTostrongSwan), [ipsec.onf parameters](https://wiki.strongswan.org/projects/strongswan/wiki/ConnSection) or [configuration examples](https://wiki.strongswan.org/projects/strongswan/wiki/IKEv2Examples)!

If all not helps, export the whole container `$ docker export vpnserver > vpn-server.tar` and examine the file system.

## Contributing

If you find a problem, please create a [GitHub Issue](https://github.com/netzfisch/rpi-vpn-server/issues).

Have a fix, want to add or request a feature? [Pull Requests](https://github.com/netzfisch/rpi-vpn-server/pulls) are welcome!

### TODOs

- [ ] Consist naming of credentials/certificates/keys/secrets etc.
- [ ] Enable adding multiple users by personalising clientCert.pem
- [x] Add initial USER with random generated PASSPHRASE if not provided
- [ ] Add nginx container to Serve ClientCert.p12
- [ ] Add container for dynamic DNS updates

### License

The MIT License (MIT), see [LICENSE](https://github.com/netzfisch/rpi-vpn-server/blob/master/LICENSE) file.
