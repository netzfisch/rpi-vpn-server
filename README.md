# VPN Server Image for the Raspberry PI

Turn your [Raspberry PI](http://raspberrypi.org) within **15 minutes** into a **VPN server** allowing **remote access** and **tunneling traffic** through your trusted home network!

This **images aims at ARM architecture**, uses the well known [stronSwan IPsec](https://www.strongswan.org/) stack, is based on [alpine Linux](http://www.alpinelinux.org/), which is with ~5 MB much smaller than most other distribution base, and thus leads to a **slimmer VPN server image**.

[![Build Status](https://travis-ci.org/netzfisch/rpi-vpn-server.svg?branch=master)](https://travis-ci.org/netzfisch/rpi-vpn-server) [![](https://images.microbadger.com/badges/version/netzfisch/rpi-vpn-server.svg)](https://microbadger.com/images/netzfisch/rpi-vpn-server "Inspect image") [![](https://images.microbadger.com/badges/image/netzfisch/rpi-vpn-server.svg)](https://microbadger.com/images/netzfisch/rpi-vpn-server "Inspect image")

Find the source code at [GitHub](https://github.com/netzfisch/rpi-vpn-server) or the ready-to-run image in the [DockerHub](https://hub.docker.com/r/netzfisch/rpi-vpn-server/) and **do not forget to _star_** the repository ;-)

## Requirements

- [Raspberry PI](http://raspberrypi.org)
- [Docker Engine](https://docs.docker.com/engine/quickstart/)
- Dynamic DNS service provider, e.g. from [Securepoint](https://www.spdns.de/)

### Setup

- **Install HypriotOS** - a Raspbian based debian derivate, which results to a fully working docker host, see [Getting Started](http://blog.hypriot.com/getting-started-with-docker-and-linux-on-the-raspberry-pi/) and download from [here](http://blog.hypriot.com/downloads/)!
- Find the PI, login, change password, update packages, configure static network interface and integrate network storage if needed:

```sh
$ nmap -sP 192.168.YOUR.IP/24 | grep black-pearl
$ ssh pirate@192.168.BLACK-PEARL.IP
$ passwd
$ sudo apt-get update && sudo apt-get upgrade
$ sudo apt-get install nfs-common
$ cat > /etc/network/interfaces.d/eth0 << EOF
  allow-hotplug eth0
  iface eth0 inet static
    address 192.168.PI.IP
    netmask 255.255.255.0
    gateway 192.168.XXX.XXX
  EOF
$ echo "192.168.NAS.IP:/nfs/Public /mnt nfs auto  0 0" >> /etc/fstab
```

- Configure your router for **dynamic DNS updates** or use  [rpi-dyndns](https://github.com/netzfisch/rpi-dyndns).
- Enable **port forwarding** at your firewall for 192.168.PI.IP and the UDP ports 500 and 4500

### Usage

Get ready to roll and run the container:

```sh
$ docker run --name vpnserver \
             --env HOSTNAME=your.domain.com \
             --env VPN_USER=name \
             --env VPN_PASSWORD=secret \
             --cap-add NET_ADMIN \
             --publish 500:500/udp \
             --publish 4500:4500/udp \
             --volume /host-directory-of-secrets:/mnt \
             --restart unless-stopped \
             --detach \
             netzfisch/rpi-vpn-server
```

In the local host-directory `/host-directory-of-secrets` you will find the encrypted PKCS#12 archive userCert.p12 and the userP12-XAUTH-Password.txt file - **be patient may take up to 2 minutes** until everything is generated! **Import userCert.p12** (unlocked by userP12-XAUTH-Password.txt) into your remote system, e.g. use

* **Android** - Install [strongSwan](https://play.google.com/store/apps/details?id=org.strongswan.android) and add new profil.
* **Linux** - Install  [network-manager](https://wiki.strongswan.org/projects/strongswan/wiki/NetworkManagerhttps://wiki.strongswan.org/projects/strongswan/wiki/NetworkManager).
* **macOS X** - Open Keychain App and import the PKCS#12 file into the system-keychain (not login) and mark as "always trusted". Than go to [Network Settings] > [Add Interface] > [VPN (IKEv2)] and enter the credentials:
  * ServerAdress = HOSTNAME
  * RemoteID = HOSTNAME
  * LocalID = VPN_USER
  * AuthenticationSettings = Certificate of VPN_USER

**Thats all** - everything below is optional!

> The **userP12-XAUTH-Password.txt** will be also used as key for **XAUTH scenarios**!

#### Dynamic DNS Updates

If you want to go wild and use the VPN access in conjunction with  [rpi-dyndns](https://github.com/netzfisch/rpi-dyndns) for dynamic DNS updates, just run it with **docker-compose**

    $ curl https://raw.githubusercontent.com/netzfisch/rpi-dyndns/master/docker-compose.yml -o rpi-vpn-server.yml
    $ env HOSTNAME=your.domain.com \
          UPDATE_TOKEN=imwg-futl-mzmw \
          VPN_USER=name \       # optional, leave away and to
          VPN_PASSWORD=secret \ # import existing secretes later!
          VPN_HOSTDIR=/host-directory-of-secrets \
          docker-compose -f rpi-vpn-server.yml up -d

**Done!**

### Manage

For manual configuration of hostname, user, password, certificates, and keys you have the following options.  

#### Create Root-Authority and Server-Credentials

Start the container without the environment variables and than execute the `setup` script with the `host` option to **create** the appropriate **server secrets**:

```sh
$ docker run --name vpnserver \
             --cap-add NET_ADMIN \
             --publish 500:500/udp \
             --publish 4500:4500/udp \
             --volume /host-directory-of-secrets:/mnt \
             --restart unless-stopped \
             --detach \
             netzfisch/rpi-vpn-server
$ docker exec vpnserver setup host your-subdomain.spdns.de
```

> **Attention** you do this normally only once, cause a **second run will invalidate credentials** ... be warned!

#### Add User

Starting the `setup` script with the option `user` and values for name and password will **create additional user**  secrets:

```sh
$ docker exec vpnserver setup user VpnUser VpnPassword
```

> If you do **not set** the password value a random one will be assigned!

#### Export/Import Secrets

To **export** do `$ docker exec vpnserver secrets export` and you will find all certificates, keys, p12-archive and userP12-XAUTH-Password.txt in the local host directory `/host-directory-of-secrets`.

To **import** put your set of **secrets** into the mounted volume `/host-directory-of-secrets` and execute:

```sh
$ docker exec vpnserver secrets import HostUrl VpnUser SecretPassword
```

> **Attention** make sure **not to change naming** of CA-, Cert- and Key-files, otherwise the import  might not work!

## Debugging

If you have trouble, **check on the running container**:

* First look at the **logs** `$ docker logs -f vpnserver`,
* get the **ipsec status** `$ docker exec vpnserver ipsec statusall` or
* **go into** for further investigation `$ docker exec -it vpnserver ash`, than
  check following commands to debug for a working configuration:

```sh
$ ipsec statusall / swanctl -L / swanctl -l
$ route -n
  Kernel IP routing table
  Destination     Gateway         Genmask         Flags Metric Ref    Use Iface
  0.0.0.0         172.17.0.1      0.0.0.0         UG    0      0        0 eth0
  172.17.0.0      0.0.0.0         255.255.0.0     U     0      0        0 eth0
$ iptables -t nat -L
  Chain PREROUTING (policy ACCEPT)
  target     prot opt source               destination
  Chain INPUT (policy ACCEPT)
  target     prot opt source               destination
  Chain OUTPUT (policy ACCEPT)
  target     prot opt source               destination
  Chain POSTROUTING (policy ACCEPT)
  target     prot opt source               destination
  MASQUERADE  all  --  anywhere             anywhere # <= IMPORTANT!
$ vi /etc/ipsec.conf
$ ipesc restart
```

If your routing is messed up (compare with above, you just NEED those TWO), **flush routes** `$ routef` and start over,
see also **strongSwan** [introduction](https://wiki.strongswan.org/projects/strongswan/wiki/IntroductionTostrongSwan), [ipsec.onf parameters](https://wiki.strongswan.org/projects/strongswan/wiki/ConnSection), [configuration examples](https://wiki.strongswan.org/projects/strongswan/wiki/IKEv2Examples) and [forwarding + split tunneling](https://wiki.strongswan.org/projects/strongswan/wiki/ForwardingAndSplitTunneling) for details!

If all not helps, export the whole container `$ docker export vpnserver > vpn-server.tar` and examine the file system.

## Contributing

If you find a problem, please create a [GitHub Issue](https://github.com/netzfisch/rpi-vpn-server/issues).

Have a fix, want to add or request a feature? [Pull Requests](https://github.com/netzfisch/rpi-vpn-server/pulls) are welcome!

### TODOs

- [x] all good!

### License

The MIT License (MIT), see [LICENSE](https://github.com/netzfisch/rpi-vpn-server/blob/master/LICENSE) file.
