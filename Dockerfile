FROM ubuntu

LABEL maintainer "guillaume.duquesnay@gmail.com"
LABEL Description="Preparing Qemu based emulation for raspberry pi (targetting hypriot) using loopback images"

# Setup working directory
RUN mkdir -p /usr/rpi
WORKDIR /usr/rpi

ARG image

COPY scripts/* /usr/rpi/
#ENV IMAGE_URL https://github.com/hypriot/image-builder-rpi/releases/download/v1.1.3/hypriotos-rpi-v1.1.3.img.zip

ENTRYPOINT ["./prepare_for_qemu"]