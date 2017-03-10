FROM ubuntu

LABEL maintainer "guillaume.duquesnay@gmail.com"
LABEL Description="Preparing Qemu based emulation for raspberry pi using loopback images"

# Update package repository
RUN apt-get update 

# Install required packages
RUN apt-get install -y --allow-unauthenticated \
    qemu \
    qemu-user-static
#    binfmt-support \
#    parted \
#    vim

# Clean up after apt
#RUN apt-get clean
#RUN rm -rf /var/lib/apt

# Setup working directory
RUN mkdir -p /usr/rpi
WORKDIR /usr/rpi

ARG image

COPY scripts/* /usr/rpi/
#ENV IMAGE_URL https://github.com/hypriot/image-builder-rpi/releases/download/v1.1.3/hypriotos-rpi-v1.1.3.img.zip

ENTRYPOINT ["./expand_sda2.sh"]
