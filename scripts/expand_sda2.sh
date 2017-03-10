#!/bin/bash
if [ "$#" -ne 2 ]; then 
    echo "Usage: $0 IMAGE SIZE"
    echo "IMAGE - raspberry pi .img file"
    exit
fi
if [ ! -f $1 ]; then
	echo "Image file $1 does not exist"
	exit 1
fi

IMAGE=$1
SIZE=$(numfmt --from=iec $2)
echo SIZE=$SIZE

function resize_img(){
	#[[ $(stat -f %z $1) -gt $SIZE ]] && exit 1
	#qemu-img resize $1 $2
	CUR_SIZE=$(stat -c%s $1)
	if [ $CUR_SIZE -gt $2 ]; then 
		echo "image already bigger $CUR_SIZE, won\'t do it" 
		exit 1 
	fi

	truncate --size=$2 $1
}

function expand_partition2(){
	fdisk $1 <<-EOF
d
2
n







w
EOF

}

function expand_filesystem(){
	loop_sda2_from_img
	e2fsck -f /dev/loop0
	resize2fs /dev/loop0
	unloop_sda2_from_img
}

function loop_sda2_from_img(){
	PART2_OFFSET=$(fdisk -l $IMAGE | grep img2 | awk '{ print $2}')
	PART2_OFFSET=$(( $PART2_OFFSET * 512 ))
	echo here is begin of partition 2 $PART2_OFFSET
	losetup -o $PART2_OFFSET /dev/loop0 $IMAGE
}

function unloop_sda2_from_img(){
	losetup -d /dev/loop0
}

function prepare_for_hypriot(){
	loop_sda2_from_img
	mkdir /media/rpi
	mount /dev/loop0 /media/rpi
	MOUNT=/media/rpi

	# Remove original preload file
	if [ -f $MOUNT/etc/ld.so.preload ]; then
		cp $MOUNT/etc/ld.so.preload $MOUNT/etc/ld.so.preload.old
		sed -i -e 's/^/#/' $MOUNT/etc/ld.so.preload
		sed -i -e 's/^snd_bcm/#snd_bcmx/' $MOUNT/etc/modules-load.d/modules.conf
	fi

	mkdir -p $MOUNT/etc/udev/rules.d/
	touch $MOUNT/etc/udev/rules.d/90-qemu.rules
	echo 'KERNEL=="sda", SYMLINK+="mmcblk0"' >> $MOUNT/etc/udev/rules.d/90-qemu.rules
	echo 'KERNEL=="sda?", SYMLINK+="mmcblk0p%n"' >> $MOUNT/etc/udev/rules.d/90-qemu.rules
	echo 'KERNEL=="sda2", SYMLINK+="root"' >> $MOUNT/etc/udev/rules.d/90-qemu.rules

	umount /media/rpi
	unloop_sda2_from_img
}

cd $(dirname $0)
echo resize_img
resize_img $IMAGE $SIZE
expand_partition2 $IMAGE
expand_filesystem
prepare_for_hypriot	