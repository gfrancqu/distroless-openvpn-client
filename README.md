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

