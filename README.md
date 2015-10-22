# backup-scripts

## Some scripts for handling LVM snapshot backups

"mengpo" is an example VM name, with respective LVM partitions.

These are shell scripts so things can easily go wrong, please
be careful.

Requires lvmtools, gpg, gzip

The SSH and GS versions share stuff and could be put into
a single file, but I figured it could be clearer separately.
Feel free to change as you wish.

## ./backup-host-gs.bash

Pushes backups to Google Cloud storage.
Requires configured gsutil (https://cloud.google.com/storage/docs/gsutil_install)

## ./backup-host-ssh.bash

Pushes backups to an SSH host. Remember to set up your private/public keys.

Depending on the filesystem layout on the backup server, you might consider
using LVM partitions, quotas, or sticky bits to take care of file permissions
and to have safeguards against filling the system by accident.
