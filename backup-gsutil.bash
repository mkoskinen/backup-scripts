#!/bin/bash
#
# Script for pushing LVM snapshots to Google Storage
# Author: Markus Koskinen - License: BSD
#
# Requires: configured gsutil, gpg, lvmtools etc
#
# Remember to configure some rotating of the resulting backup files.

##############################################
# Configurations
##############################################

### Mandatory configurations
### These 6 args need to be exported in a parent script or given as args.

# Google Storage bucket name
#BUCKET="gs-backup"

# LVM Volume group name and volume name, check with "lvdisplay"
#VOLGROUP="vg_kvm01_ssd"
#VOLNAME="mengpo"

# This file contains the symmetric passphrase, any random string
#PASSFILE="/root/backup-scripts/mengpo.pwd"

# LVM snapshot size in "-L" format. This should be greater
# than the amount of changes on the source volume during
# the backup upload process
#SNAPSIZE="3G"

# Cleanup. How many snapshots you want to keep. 0 is infinite.
#SNAPSHOT_RETENTION_COUNT=4

### Optional configurations
# Optional config defaults are set in 'set_optional_defaults'.
# They can be overridden by setting them in th eparent script.

##############################################
# Please do not edit below this line
##############################################

function set_optional_defaults {
  # More cleanup. Only remove files with this suffix. Set "" to rotate all.
  if [ -z "${SNAPSHOT_ROTATION_SUFFIX+x}" ]; then SNAPSHOT_ROTATION_SUFFIX="/*.dd.gz.gpg"; fi

  # REMOTEDIR - A directory within the bucket
  if [ -z "${REMOTEDIR+x}" ]; then REMOTEDIR="${VOLNAME}"; fi

  # Arbitrary snapshot name, used for backup filename as well
  # Just needs to be unique and descriptive
  if [ -z "${SNAPNAME+x}" ]; then SNAPNAME="snap_${VOLNAME}"; fi

  # gsutil path (do not use quotes if using tilde)
  if [ -z "${GSUTIL+x}" ]; then GSUTIL=~/gsutil/gsutil; fi

  # PROTOCOL is either gs or s3, defaults to gs
  if [ -z "${PROTOCOL+x}" ]; then PROTOCOL=gs; fi

  # gsutil switches. we set -q to suppress upgrade prompt
  if [ -z "${GSUTIL_SWITCHES+x}" ]; then GSUTIL="${GSUTIL} -q"; fi
}

# Clean up old snapshots, if needed
function snapshot_cleanup {
  if [ "$SNAPSHOT_RETENTION_COUNT" -eq 0 ]
  then
    # If $SNAPSHOT_RETENTION_COUNT is set to 0, we don't "rotate"
    return
  fi

  SNAPSHOT_LIST=$($GSUTIL ls "${PROTOCOL}"://"${BUCKET}"/"${REMOTEDIR}""${SNAPSHOT_ROTATION_SUFFIX}"|sort|uniq|sort)
  SNAPSHOT_COUNT=$(echo "${SNAPSHOT_LIST}"|wc -l)

  while [ "$SNAPSHOT_COUNT" -gt "$SNAPSHOT_RETENTION_COUNT" ]
  do
    echo "Snapshot count = $SNAPSHOT_COUNT"
    REMOVEFILE=$(echo "${SNAPSHOT_LIST}"|head -n1)
    echo "File to remove = ${REMOVEFILE}"

    if ! $GSUTIL rm "${REMOVEFILE}"; then
      >&2 echo "ERROR: $0, Could not perform snapshot cleanup. Check your permissions."
      return
    fi

    SNAPSHOT_LIST=$($GSUTIL ls "${PROTOCOL}"://"${BUCKET}"/"${REMOTEDIR}"|sort|uniq|sort)
    SNAPSHOT_COUNT=$(echo "${SNAPSHOT_LIST}"|wc -l)
  done
}

# A connection test with gsutil, if it fails we don't continue
function gsutil_check {
    if ! $GSUTIL ls "${PROTOCOL}"://${BUCKET}" > /dev/null; then
      >&2 echo "ERROR: $0, Could not access your storage bucket. Check your boto settings. Exiting."
      exit 1
    fi  
}

function syntax {
  >&2 echo "ERROR: $0, arguments or mandatory exported variables missing. Please review the documentation."
  exit 1
}

# Cursory syntax check. We expect 0 or 6 arguments.
# 0 arguments : you are colling this from another shellscript and export the needed variables
# 6 arguments : You are calling this manually or from cron, specifying the needed variables
function syntax_check {
  arg_arr=("${BUCKET}" "${VOLGROUP}" "${VOLNAME}" "${PASSFILE}" "${SNAPSIZE}" "${SNAPSHOT_RETENTION_COUNT}")

  if [ $# -eq 6 ]
  then
    # Set mandatory values from command line args
    BUCKET=$1
    VOLGROUP=$2
    VOLNAME=$3
    PASSFILE=$4
    SNAPSIZE=$5
    SNAPSHOT_RETENTION_COUNT=$6
  elif [ $# -eq 0 ]
  then
    # Check that the mandatory variables exist
    for val in "${arg_arr[@]}"
    do
      if [ -z "${val+xxx}" ]; then syntax; exit 1; fi
      if [ -z "$val" ] && [ "${val+xxx}" = "xxx" ]; then syntax; exit 1; fi
    done
  else
    syntax "$@"
  fi
}

# Create an LVM snapshot and push it to GS, then release
function push_snapshot {
  # Create a snapshot
  /usr/sbin/lvcreate -L"${SNAPSIZE}" -s -n "${SNAPNAME}" "/dev/${VOLGROUP}/${VOLNAME}"

  # DD the image through gzip and gsutil
  # With GPG, gzip forked as --fast in other process.
  echo "dd started at: $(date)"
  /bin/dd if="/dev/${VOLGROUP}/${SNAPNAME}" bs=128k status=none|\
     /bin/nice -n 19 /bin/gzip --fast -|\
     /bin/nice -n 19 /usr/bin/gpg -z 0 -c --batch --no-tty --passphrase-file "${PASSFILE}" |\
     ${GSUTIL} -q cp - gs://"${BUCKET}"/"${REMOTEDIR}"/"${SNAPNAME}"-"$(date +%Y%m%d-%H%M.dd.gz.gpg)"
  echo "dd ended at: $(date)"

  # Drop the snapshot
  /usr/sbin/lvremove -f "/dev/${VOLGROUP}/${SNAPNAME}"
}

# "Main"
syntax_check "$@"
set_optional_defaults "$@"
gsutil_check "$@"
snapshot_cleanup "$@"
push_snapshot "$@"
