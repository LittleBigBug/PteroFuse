FROM --platform=$TARGETOS/$TARGETARCH debian:stable-slim

LABEL author="Ethan Jones" maintainer="ethan@yasfu.net"

ENV DEBIAN_FRONTEND=noninteractive

RUN dpkg --add-architecture i386 \
    && apt-get update -y \
    && apt-get upgrade -y \
    && apt-get install -y unionfs-fuse git tar curl gcc g++ lib32gcc-s1 libgcc1 libcurl4-gnutls-dev:i386  \
      libstdc++6 libc6 debconf libcurl4:i386 lib32tinfo6 libtinfo6:i386 lib32z1 lib32stdc++6 libncurses5:i386 \
      libbz2-1.0:i386 libtinfo5:i386 software-properties-common libcurl3-gnutls:i386 libsdl2-2.0-0:i386 \
      iproute2 gdb libsdl1.2debian libfontconfig1 telnet net-tools netcat-traditional tzdata

RUN useradd -m -d /home/container container

USER container
ENV USER=container HOME=/home/container
WORKDIR /home/container

COPY eggs/source/entrypoint.sh /entrypoint.sh
COPY eggs/pterofuse-start.sh /pterofuse-start.sh

CMD [ "/bin/bash", "/entrypoint.sh" ]