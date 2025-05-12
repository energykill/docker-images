# Dockerfile with SteamRT3 
FROM        registry.gitlab.steamos.cloud/steamrt/sniper/platform:latest-container-runtime-depot
LABEL       author="m3ntor" maintainer="m3ntor@energykill.net"
LABEL       org.opencontainers.image.description SteamRT3 Platform image for Pterodactyl CSGO/CS2/Source engine servers. 
LABEL       org.opencontainers.image.source="https://github.com/energykill/docker-images/cs2"

# Prep OS
RUN         mkdir -p /etc/sudoers.d && echo "%sudo ALL=(ALL:ALL) NOPASSWD: ALL" > /etc/sudoers.d/flatdeb && chmod 0440 /etc/sudoers.d/flatdeb
ENV         DEBIAN_FRONTEND=noninteractive
RUN         apt update && apt install -y iproute2 && apt install -y curl unzip &&  apt-get clean
USER        container
ENV         USER=container HOME=/home/container
WORKDIR     /home/container

# To-Do: If CS2 requires Wine, the following lines will need to be uncommented
# RUN         apt update
# RUN         apt install -y wine wine64 libwine && apt clean

# EP
COPY        ./entrypoint.sh /entrypoint.sh
CMD         [ "/bin/bash", "/entrypoint.sh" ]