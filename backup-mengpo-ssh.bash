#!/bin/bash
#
# Script for pushing LVM snapshots to an SSH host
# Author: Markus Koskinen - License: BSD
#
# Requires: configured ssh keys, gpg, lvmtools etc
#
# Remember to configure some rotating of the resulting
# backup files.

##############################################
# Configurations
##############################################

# LVM Volume group name and volume name, check with "lvdisplay"
VOLGROUP="vg_kvm01_ssd"
VOLNAME="mengpo"
# This file contains the symmetric passphrase, any random string
PASSFILE="/root/backup-scripts/mengpo.pwd"
# LVM snapshot size in "-L" format. This should be greater
# than the amount of changes on the source volume during
# the backup upload process
SNAPSIZE="3G"

# Target host and user, with public/private keys configured
REMOTE="backup-kvm01@backup-box.example.com"
# A directory within the bucket
REMOTEDIR="/mnt/mengpo/"
# Arbitrary snapshot name, used for backup filename as well
# Just needs to be unique and descriptive
SNAPNAME="snap_${VOLNAME}"
# SSH port (usually 22)
SSH_PORT=22

##############################################
# Do not edit below this line
##############################################

# Create a snapshot (WARNING: currently set to 10G changes)
/usr/sbin/lvcreate -L${SNAPSIZE} -s -n "${SNAPNAME}" "/dev/${VOLGROUP}/${VOLNAME}"

# DD the image through gzip and gsutil
# With GPG, gzip forked as --fast in other process.
/usr/bin/time /bin/dd if="/dev/${VOLGROUP}/${SNAPNAME}" bs=128k |\
   /bin/nice -n 19 /bin/gzip --fast -|\
   /bin/nice -n 19 /usr/bin/gpg -z 0 -c --batch --no-tty --passphrase-file "${PASSFILE}" |\
   /usr/bin/ssh -p ${SSH_PORT} "${REMOTE}" \
      "/bin/cat > ${REMOTEDIR}/${SNAPNAME}-$(date +%Y%m%d-%H%M.dd.gz.gpg)"

# Drop the snapshot
/usr/sbin/lvremove -f "/dev/${VOLGROUP}/${SNAPNAME}"
