FROM gcc as builder

ENV VERSION 2.4.7
ENV OPENSSL_VERSION 1_1_1c
ENV LZO_VERSION 2.10

# downloads openssl, lzo, openvpn and net tools
WORKDIR /
RUN apt update -q && \
    apt install -y net-tools && \
    mkdir vpn_compile && \
    wget https://github.com/openssl/openssl/archive/OpenSSL_${OPENSSL_VERSION}.tar.gz && \
    tar -zxvf OpenSSL_${OPENSSL_VERSION}.tar.gz && \
    wget http://www.oberhumer.com/opensource/lzo/download/lzo-${LZO_VERSION}.tar.gz && \
    tar -zxvf lzo-${LZO_VERSION}.tar.gz && \
    wget https://swupdate.openvpn.org/community/releases/openvpn-${VERSION}.tar.gz && \
    tar -zxvf openvpn-${VERSION}.tar.gz && \
    git clone https://github.com/ecki/net-tools

# build static openssl 
WORKDIR /openssl-OpenSSL_${OPENSSL_VERSION}
RUN ./Configure gcc -static -no-shared --prefix=/vpn_compile && \
    make && \
    make install

# build static lzo
WORKDIR /lzo-${LZO_VERSION}
RUN ./configure --prefix=/vpn_compile --enable-static --disable-debug && \
    make && make install

# build static openvpn 
# (only the client: --disable-server)
WORKDIR /openvpn-${VERSION}
RUN ./configure --prefix=/vpn_compile \
    --disable-server \
    --enable-static \
    --disable-shared \
    --disable-debug \
    --disable-plugins \
    OPENSSL_SSL_LIBS="-L/vpn_compile/lib -lssl" \
    OPENSSL_SSL_CFLAGS="-I/vpn_compile/include" \
    OPENSSL_CRYPTO_LIBS="-L/vpn_compile/lib -lcrypto" \
    OPENSSL_CRYPTO_CFLAGS="-I/vpn_compile/include" \
    LZO_CFLAGS="-I/vpn_compile/include" \
    LZO_LIBS="-L/vpn_compile/lib -llzo2" && \
    make LIBS="-all-static -L/vpn_compile/lib -lssl -lcrypto -llzo2" && \
    make install

# let's build ifconfig and route utilities as openvpn need them
WORKDIR /net-tools

# next for lines are a trick, because net-tools makefile start and interactive configuration session
# I hard coded the configuration
COPY config.status config.status
COPY config.h config.h
COPY config.in config.in
# and I deleted the configuration script
# TODO : find a better fashion to do so ?
RUN echo "" > configure.sh 

# this build static version of ifconfig and route utility
# TODO : switch to iproute2 ?
RUN make ifconfig LDFLAGS="-Llib -static" && \
    make route LDFLAGS="-Llib -static"

# oh yeah 
FROM gcr.io/distroless/base
COPY --from=builder /vpn_compile/sbin/openvpn /openvpn
COPY --from=builder /net-tools/ifconfig /sbin/ifconfig
COPY --from=builder /net-tools/route /sbin/route

CMD ["/openvpn", "--config", "/default.ovpn"]
