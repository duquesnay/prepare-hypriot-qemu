# prepare-hypriot-emu
Dockerized script to prepare a hypriot disk image for running under qemu
- include enlargement of image and adjustment of filesystem
- using only raw ubuntu tools to keep the container minimal

Parameters are 
1. IMG - path in docker (so you may need to mount image folder somewhere within docker container)
2. size - in human readable form (1M, 8G, etc)

```bash
docker run --privileged=true -v $(pwd)/../images:/usr/rpi/images duquesnay/prepare-hypriot-emu images/hypriotos-rpi-v1.1.3.img 8G
```
