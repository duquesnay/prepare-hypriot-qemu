# prepare-hypriot-emu
Dockerized script to prepare a hypriot disk image for running under qemu
- include enlargement of image and adjustment of filesystem
- using only raw ubuntu tools to keep the container minimal

** Tested on hypriot v1.1.3 public image **

Parameters are 

1. IMG - path in docker (so you may need to mount image folder somewhere within docker container)
2. size - in human readable form (1M, 8G, etc)

```bash
docker run --privileged=true -v $(pwd)/../images:/usr/rpi/images duquesnay/prepare-hypriot-emu images/hypriotos-rpi-v1.1.3.img 8G
```
Then run it with qemu such as (macos version, require downloading proper kernel externally, network access unrestriced; tune to your own needs)
```bash
APPEND_ARGS="root=/dev/sda2 panic=1 rw loglevel=8 console=ttyAMA0,115200"
qemu-system-arm   -cpu arm1176   -m 256   -M versatilepb \
	-no-reboot   -serial stdio   \
	-append "${APPEND_ARGS}" \
	-kernel kernel/kernel-qemu-4.4.34-jessie \
	-net nic -net user,restrict=off  \
	-drive file=$(pwd)/images/hypriotos-rpi-v1.1.3.img,index=0,media=disk,format=raw
```
