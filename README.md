# DISTROLESS OPENVPN CLIENT
This image is a [distroless](https://github.com/GoogleContainerTools/distroless) version of an openvpn client

## Quick start

Run the client, you need to add the `NET_ADMIN` capabilities and share your `/dev/net/tun` device.

```bash
docker run -d -v [path to .ovpn config]:/default.ovpn --cap-add NET_ADMIN --device /dev/net/tun --name vpn distroless-openvpn-client
```

Share container network in order to use vpn in another container

```bash

docker run -it --network container:vpn ubuntu
~#: curl ifconfig.me
```

### Testing

try to reach ifconfig.me, `curl ifconfig.me`, this should give a different result in your container than on your host

### Build image

```bash
docker build -t distroless-openvpn-client .
```

### use in compose file

```yaml
openvpn:
    image: gfrancqu/distroless-openvpn-client
    volumes:
      - /path/to/my/config.ovpn:/default.ovpn
    dns:
      - 208.67.222.222
      - 208.67.222.220
    cap_add:
      - NET_ADMIN
    devices:
      - /dev/net/tun

  transmission:
    depends_on: 
      - openvpn
    image: dperson/transmission
    network_mode: service:openvpn
```

note the `network_mode: service:openvpn` this allow containers to share the same network stack
