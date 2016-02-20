# rpi-vpn-server

## Run

## Debugging

If you have trouble, **check on the running container**:

* First look at the **logs** `$ docker logs -f vpnserver`,
* get the **ipsec status** `$ docker exec vpnserver ipsec statusall` or
* **go into** for further investigation `$ docker exec -it vpnserver ash`, than
  * `$ vi /etc/ipsec.conf`
  * `$ ipesc reload`
  * `$ ipsec status`
* If that all not helps, export the whole file system `$ docker export vpnserver > vpn-server.tar

## TODO

* Interactive adding and removing of users/keys
* Serve client ClientCert.p12 via annother nginx container
