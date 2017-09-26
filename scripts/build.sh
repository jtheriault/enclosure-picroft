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
curl -o raspbian-jessie-lite.zip $RASPBIAN_ZIP_URL
unzip raspbian-jessie-lite.zip
mv *.img raspbian.img

# 3. Mount Raspbian image
SECTOR_START=$(fdisk -l raspbian.img | grep Linux | xargs | cut -d " " -f2)
let "OFFSET = $SECTOR_START * 512"
mkdir raspbian
sudo mount -v -o offset=$OFFSET -t ext4 raspbian.img ./raspbian

# 4. Install ARM emulator
sudo apt install qemu-system-arm

# 5. Download MyCroft standalone install
curl -o raspbian/standalone.sh http://bootstrap.mycroft.ai/standalone.sh

# 6. chroot, sudo bash run standalone.sh
chroot raspbian ./standalone.sh

# 7. copy folders into image
sudo cp -R ../etc/* raspbian/etc/
sudo cp -R ../home/* raspbian/home/

# 8. unmount image
sync
sudo umount raspbian

# 9. Name build
mv raspbian.img picroft-$PICROFT_VERSION.img
zip picroft-$PICROFT_VERSION.img.zip picroft-$PICROFT_VERSION.img

