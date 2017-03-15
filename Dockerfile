FROM ubuntu

LABEL maintainer "guillaume.duquesnay@gmail.com"
LABEL Description="Preparing Qemu based emulation for raspberry pi (targetting hypriot) using loopback images"

# Setup working directory
RUN mkdir -p /usr/rpi
WORKDIR /usr/rpi

COPY ./prepare_for_qemu /usr/rpi/

ENTRYPOINT ["./prepare_for_qemu"]