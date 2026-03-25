#!/bin/bash

DEFAULT_IMG_DIR="$HOME/images"
DEFAULT_LOG_DIR="$HOME/logs"

if ! command -v pv &> /dev/null; then
    echo "Installing pv..."
    sudo apt install -y pv
fi

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

if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
	echo "aborted"
	exit 0
fi

echo ""
read -p "Use default directories? (Images: $DEFAULT_IMG_DIR, Logs: $DEFAULT_LOG_DIR (Y/N): " CONFIRM2

if [[ ! "$CONFIRM2" =~ ^[Yy]$ ]]; then
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
LOGFILE="$LOG_DIR/${DISK}_$TIMESTAMP.txt"


DEVICE_SIZE=$(lsblk -bdn -o SIZE "$DEVICE")

#Source Hashing 
echo "--- Source Device Hash ---" >> "$LOGFILE"
SOURCE_SHA=$(sudo pv -p -t -e -r -s "$DEVICE_SIZE" "$DEVICE" | tee >(md5sum > /tmp/source_md5.tmp) | sha256sum | awk '{print $1}')
SOURCE_MD5=$(awk '{print $1}' /tmp/source_md5.tmp)
echo "$SOURCE_SHA  $DEVICE (sha256)" >> "$LOGFILE"
echo "$SOURCE_MD5  $DEVICE (md5)"    >> "$LOGFILE"
echo ""                              >> "$LOGFILE"
echo "Source hashing complete."
echo ""
 
#Imaging 
sudo dd if="$DEVICE" of="$IMGFILE" bs=4M status=progress conv=noerror,sync
echo ""
echo "Imaging complete: $IMGFILE"
echo ""
 
#Image Hashing 
echo "Step 3: Hashing image file..."
IMG_SIZE=$(stat -c%s "$IMGFILE")
echo "--- Original Image Hash ---" >> "$LOGFILE"
IMAGE_SHA=$(pv -p -t -e -r -s "$IMG_SIZE" "$IMGFILE" | tee >(md5sum > /tmp/image_md5.tmp) | sha256sum | awk '{print $1}')
echo "Step 1: Hashing source device (this may take a while)..."
DEVICE_SIZE=$(lsblk -bdn -o SIZE "$DEVICE")
echo "--- Source Device Hash ---" >> "$LOGFILE"
SOURCE_SHA=$(sudo pv -p -t -e -r -s "$DEVICE_SIZE" "$DEVICE" | tee >(md5sum > /tmp/source_md5.tmp) | sha256sum | awk '{print $1}')
SOURCE_MD5=$(awk '{print $1}' /tmp/source_md5.tmp)
echo "$SOURCE_SHA  $DEVICE (sha256)" >> "$LOGFILE"
echo "$SOURCE_MD5  $DEVICE (md5)"    >> "$LOGFILE"
echo ""                              >> "$LOGFILE"
echo "Source hashing complete."
echo ""

# ---- STEP 6: Validate all three hashes ----
echo "Step 6: Validating hashes..."
echo "--- Validation Summary ---"    >> "$LOGFILE"
echo "SHA256 - Source : $SOURCE_SHA" >> "$LOGFILE"
echo "SHA256 - Image  : $IMAGE_SHA"  >> "$LOGFILE"
echo ""                              >> "$LOGFILE"
echo "MD5    - Source : $SOURCE_MD5" >> "$LOGFILE"
echo "MD5    - Image  : $IMAGE_MD5"  >> "$LOGFILE"
echo ""                              >> "$LOGFILE"
 
# SHA256 check
if [ "$SOURCE_SHA" = "$IMAGE_SHA" ] && [ "$IMAGE_SHA" = "$COPY_SHA" ]; then
    SHA_RESULT="PASSED"
else
    SHA_RESULT="FAILED"
fi
 
# MD5 check
if [ "$SOURCE_MD5" = "$IMAGE_MD5" ] && [ "$IMAGE_MD5" = "$COPY_MD5" ]; then
    MD5_RESULT="PASSED"
else
    MD5_RESULT="FAILED"
fi
 
echo "SHA256 Validation : $SHA_RESULT" >> "$LOGFILE"
echo "MD5    Validation : $MD5_RESULT" >> "$LOGFILE"
 
# Cleanup temp files
rm -f /tmp/source_md5.tmp /tmp/image_md5.tmp /tmp/copy_md5.tmp
 
# Print result to terminal
echo ""
echo "==============================="
echo " SHA256 Validation : $SHA_RESULT"
echo " MD5    Validation : $MD5_RESULT"
echo "==============================="
echo ""
 
if [ "$SHA_RESULT" = "PASSED" ] && [ "$MD5_RESULT" = "PASSED" ]; then
    echo "All hashes match. Forensic integrity confirmed." | tee -a "$LOGFILE"
else
    echo "WARNING: Hash mismatch detected. Image may not be forensically sound." | tee -a "$LOGFILE"
fi
 
echo ""
echo "Log saved to: $LOGFILE"
echo "Done."IMAGE_MD5=$(awk '{print $1}' /tmp/image_md5.tmp)
echo "$IMAGE_SHA  $IMGFILE (sha256)" >> "$LOGFILE"
echo "$IMAGE_MD5  $IMGFILE (md5)"    >> "$LOGFILE"
echo ""                              >> "$LOGFILE"
echo "Image hashing complete."
echo ""
 


 

echo "--- Validation Summary ---"    >> "$LOGFILE"
echo "SHA256 - Source : $SOURCE_SHA" >> "$LOGFILE"
echo "SHA256 - Image  : $IMAGE_SHA"  >> "$LOGFILE"
echo ""                              >> "$LOGFILE"
echo "MD5    - Source : $SOURCE_MD5" >> "$LOGFILE"
echo "MD5    - Image  : $IMAGE_MD5"  >> "$LOGFILE"
echo ""                              >> "$LOGFILE"
 

if [ "$SOURCE_SHA" = "$IMAGE_SHA" ]; then
    SHA_RESULT="PASSED"
else
    SHA_RESULT="FAILED"
fi
 

if [ "$SOURCE_MD5" = "$IMAGE_MD5" ]; then
    MD5_RESULT="PASSED"
else
    MD5_RESULT="FAILED"
fi
 
echo "SHA256 Validation : $SHA_RESULT" >> "$LOGFILE"
echo "MD5    Validation : $MD5_RESULT" >> "$LOGFILE"
 

rm -f /tmp/source_md5.tmp /tmp/image_md5.tmp
 

echo ""
echo " SHA256 Validation : $SHA_RESULT"
echo " MD5    Validation : $MD5_RESULT"
echo ""
 
if [ "$SHA_RESULT" = "PASSED" ] && [ "$MD5_RESULT" = "PASSED" ]; then
    echo "All hashes match. Forensic integrity confirmed." | tee -a "$LOGFILE"
else
    echo "WARNING: Hash mismatch detected. Image may not be forensically sound." | tee -a "$LOGFILE"
fi
 
echo ""
echo "Log saved to: $LOGFILE"
echo "Done."
