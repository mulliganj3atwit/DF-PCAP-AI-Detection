#!/bin/bash

DEFAULT_IMG_DIR="$HOME/images"
DEFAULT_LOG_DIR="$HOME/logs"

echo "Avalible disks"

lsblk -d -o NAME,SIZE,MODEL,TRAN

echo ""
read -p "Enter Disk img (sda, nvme):   " DISK

DEVICE="/dev/$DISK"

if [ ! -b "$DEVICE" ]; then
	echo "Invalid device"
	exit 1
fi

echo ""

echo "Device Info"

lsblk -o NAME,SIZE,MODEL,MOUNTPOINT $DEVICE
udevadm info  --query=property --name=$DEVICE | grep -E "ID_BUS|ID_MODEL|ID_SERIAL"

echo ""
read -p "Image this device $DEVICE?? (Y/N): " CONFIRM

if [ "$CONFIRM" != "y" ]; then
	echo "aberted"
	exit 0
fi

echo ""
read -p "Use default directories? (Images: $DEFAULT_IMG_DIR, Logs: $DEFAULT_LOG_DIR (Y/N): " CONFIRM2

if [ "$CONFIRM2" != "y" ]; then
	read -p "Enter Image Destnation: " IMG_DIR
	read -p "Enter Log Destination: " LOG_DIR
else
	IMG_DIR="$DEFAULT_IMG_DIR"
	LOG_DIR="$DEFAULT_LOG_DIR"
fi

mkdir -p "$IMG_DIR"
mkdir -p "$LOG_DIR"


TIMESTAMP=$(date +%F_%H-%M-%S)

IMGFILE="$IMG_DIR/${DISK}_$TIMESTAMP.img"
COPYFILE="$IMG_DIR/${DISK}_$TIMESTAMP.copy.img"
LOGFILE="$LOG_DIR/${DISK}_$TIMESTAMP.txt"


echo ""
echo "Trying Imaging..."

sudo dd if="$DEVICE" of="$IMGFILE" bs=4M status=progress conv=noerror,sync

echo "Imaging complete $IMGFILE"
echo ""
echo "hashign Orginal Image ..."

echo "Original Image Hash" >> "$LOGFILE"
sha256sum "$IMGFILE" >> "$LOGFILE"
md5sum "$IMGFILE" >> "$LOGFILE"
echo "" >> "$LOGFILE"

echo "Creating Copy ..."
cp "$IMGFILE" "$COPYFILE"

echo ""
echo "Hashing Copy"

echo "Copied Image Hash" >> "$LOGFILE"
sha256sum "$COPYFILE" >> "$LOGFILE"
md5sum "$COPYFILE" >> "$LOGFILE"


echo ""
echo "Imaging Complete!!"
