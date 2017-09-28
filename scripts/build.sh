#!/usr/bin/env bash

# 0. Handle special case of interactive use
if [ -z $RASPBIAN_ZIP_URL ]; then
    read -p "URL of Raspbian zip file: " RASPBIAN_ZIP_URL 
fi

if [ -z $PICROFT_VERSION ]; then
    read -p "Version being built: " PICROFT_VERSION
fi

if [ "$(basename $(pwd))" = "build" ] || [ "$(basename $(pwd))" = "scripts" ]; then
    cd ..
fi

# 1. Prepare workspace
mkdir -p build
cd build

# 2. Get Raspbian image into place
curl -o raspbian-lite.zip $RASPBIAN_ZIP_URL
unzip raspbian-lite.zip
mv *.img raspbian.img

# 3. Load Raspbian image

# 3.1 Grow image file to add space for Mycroft
dd if=/dev/zero bs=1M count=512 >> raspbian.img
IMAGE_END=$(parted raspbian.img print free | tail -n2 | xargs | cut -d ' ' -f2 | cut -d 'M' -f1)
parted raspbian.img resizepart 2 $IMAGE_END

# 3.2 Mount Raspbian image
SECTOR_START=$(fdisk -l raspbian.img | grep Linux | xargs | cut -d " " -f2)
let "OFFSET = $SECTOR_START * 512"
mkdir raspbian
LOOP_MOUNT_DEVICE=$(sudo mount -v -o offset=$OFFSET -t ext4 raspbian.img ./raspbian | egrep -o '/dev/\w+')

# 3.3 Expand file system
sudo resize2fs $LOOP_MOUNT_DEVICE

# 4. Install ARM emulator
sudo apt-get install qemu-user-static
sudo cp $(which qemu-arm-static) raspbian/usr/bin

# 5. Embed Mycroft installation script
sudo cp ../scripts/mycroft-install.sh raspbian/

# 6. chroot, sudo bash run standalone.sh
sudo chroot raspbian qemu-arm-static /bin/bash mycroft-install.sh
sudo rm raspbian/mycroft-install.sh

# 7. copy folders into image
sudo cp -R ../etc/* raspbian/etc/
sudo cp -R ../home/* raspbian/home/

# 8. unmount image
sync
sudo umount raspbian

# 9. Name build
mv raspbian.img picroft-$PICROFT_VERSION.img
zip picroft-$PICROFT_VERSION.img.zip picroft-$PICROFT_VERSION.img

