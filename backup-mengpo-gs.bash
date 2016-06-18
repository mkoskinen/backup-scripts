#!/bin/bash
#
# An example of a file calling 'backup-gs.bash'.
# This would define the required settings for one
# partition.
# The first 6 values are mandatory. The remaing ones
# have reasonable defaults if they are unset or null.
#
# Author: Markus Koskinen - License: BSD
#

# Mandatory configurations

export BUCKET="gs-backup" # Google storage bucket name
export VOLGROUP="vg_kvm01_ssd" # LVM group name (check with 'lvdisplay')
export VOLNAME="mengpo" # LVM volume name
export PASSFILE="/root/backup-scripts/mengpo.pwd" # File with GPG passphrase
export SNAPSIZE="3G" # LVM snapshot size, "-L" format
export SNAPSHOT_RETENTION_COUNT=7 # Amount of snapshots to keep. 0 is infinite.

# Optional configurations

#export SNAPSHOT_ROTATION_SUFFIX="/*.dd.gz.gpg" # Only remove files with this suffix. Set "" to rotate all.
#export REMOTEDIR="${VOLNAME}" # A directory within the bucket
#export SNAPNAME="snap_${VOLNAME}" # Unique snapshot name
export GSUTIL=/bin/gsutil # gsutil path (do not use quotes if using tilde)

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
"${DIR}"/backup-gs.bash
