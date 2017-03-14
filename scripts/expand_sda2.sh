#!/bin/bash
if [ "$#" -ne 2 ]; then 
    echo "Usage: $0 IMAGE SIZE"
    echo "IMAGE - raspberry pi .img file"
    echo "SIZE - size in bash human readable format (see 'iec' numeric format)"
    exit
fi
if [ ! -f $1 ]; then
	echo "Image file $1 does not exist"
	exit 1
fi

IMAGE=$1
SIZE=$(numfmt --from=iec $2)

function resize_img(){
	#[[ $(stat -f %z $1) -gt $SIZE ]] && exit 1
	#qemu-img resize $1 $2
	CUR_SIZE=$(stat -c%s $1)
	echo resizing $1 to $2
	if [ $CUR_SIZE -ge $2 ]; then 
		echo "original size ${CUR_SIZE}, already >= $2, no need expand" 
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

function check_filesystem(){
	loop_sda2_from_img
	e2fsck -fp /dev/loop0
	unloop_sda2_from_img
}

function expand_filesystem(){
	loop_sda2_from_img
	resize2fs /dev/loop0
	unloop_sda2_from_img
}

function loop_sda2_from_img(){
	PART2_OFFSET=$(fdisk -l $IMAGE | grep img2 | awk '{ print $2}')
	PART2_OFFSET=$(( $PART2_OFFSET * 512 ))
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
		cp $MOUNT/etc/ld.so.{,.old}
		sed -i -e 's/^/#/' $MOUNT/etc/ld.so.preload
	fi

	cp $MOUNT/etc/modules-load.d/modules.conf{,.old}
	sed -i -e 's/^snd_bcm/#snd_bcmx/' $MOUNT/etc/modules-load.d/modules.conf
	
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
if [[ $? -eq "0" ]]; then
	echo ">>> Image extended to $(numfmt --to=iec $SIZE)"
	expand_partition2 $IMAGE
	echo ">>> Partition table updated to new size"
	check_filesystem
	echo ">>> Filesystem checked"
	expand_filesystem
	echo ">>> Filesystem updated to new partition size"
fi
prepare_for_hypriot	
echo ">>> Hypriot conf adapted to qemu subtelties"
