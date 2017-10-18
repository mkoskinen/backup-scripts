# backup-scripts

### Some scripts for handling LVM snapshot backups

The idea of these scripts is to take LVM snapshots of LVM partitions,
compress, encrypt and push them to cloud storage or a remote SSH server.
You can launch these through cron.

*These are shell scripts so things can easily go wrong, please
be careful.*

"mengpo" is an example VM name, with respective LVM partitions.

Requires lvmtools, gpg, gzip

The SSH and GS versions share stuff and could be put into
a single file, but I figured it could be clearer separately.

Feel free to change as you wish.

#### TODO ###

Make the SSH version similar to the GS version, so that
it can be called with command line arguments or exported
variables from a parent script.

### ./backup-gsutil.bash

Pushes backups to Google Cloud storage.
Requires configured gsutil (https://cloud.google.com/storage/docs/gsutil_install)

Supports crude rotating of old backups. Set SNAPSHOT_RETENTION_COUNT variable
to the amount of backups you want to store.

SNAPSHOT_ROTATION_SUFFIX can be set as a crude filter to avoid touching other
files in the directory. Normally you should not store other files in the
directories.

A more sophisticated system for cleanup is suggested though. You should not let
the user that pushes the backups be able to remove them afterwards.

You can call backup-gs.bash directly with the required 6 arguments, or perhaps
more preferably make a wrapper shell script for each partition that exports
the required variables. Please see 'backup-mengpo-gs.bash' for an example.

### ./backup-s3.bash

Very similar to the gsutil script, but uses aws cli. Gsutil used to be ok
to use for both S3 and GS, but unfortunately it is no longer actively
maintained and doesn't support eg Frankfurt S3. Also has other issues.

### ./backup-host-ssh.bash

Pushes backups to an SSH host. Remember to set up your private/public keys.

Depending on the filesystem layout on the backup server, you might consider
using LVM partitions, quotas, or sticky bits to take care of file permissions
and to have safeguards against filling the system by accident.

### Extracting / Recovering

Again "mengpo" and "gs-backup" are just example names

From file:

```
% gpg -d --batch --passphrase-file mengpo.pwd snap_mengpo-20151022-0800.dd.gz.gpg|gunzip -> targetfile_or_device.dd
```

From stream:

```
% gsutil cp gs://gs-backup/mengpo/snap_mengpo-20151022-0800.dd.gz.gpg -|gpg -d --passphrase-file mengpo.pwd -|gunzip -> targetfile_or_device.dd
```
From stream:

```
% time aws s3 cp s3://s3-backup/mengpo/snap_mengpo-20170906-0130.dd.gz.gpg -|gpg -d --batch --passphrase-file ~/backup-scripts/mengpo.pwd -|gunzip ->/dev/vgrestore/mengpo
```

### Known issues

It is not recommeded to use gsutil with S3 anymore. It doesn't support
SIGV4 and will not work with new S3 regions like Frankfurt.
