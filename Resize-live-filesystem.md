# pivot_root, lvm OR btrfs

    https://www.howtoforge.com/a-beginners-guide-to-btrfs

Source: http://www.ivarch.com/blogs/oss/2007/01/resize-a-live-root-fs-a-howto.shtml

1.  Stop all services other than the network and SSH, and stop SELinux interfering:

```
    telinit 2
    for SERVICE in \
      $(chkconfig --list | grep 2:on | awk '{print $1}' | grep -v -e sshd -e network -e rawdevices); \
      do service $SERVICE stop; done
    service nfs stop
    service rpcidmapd stop
    setenforce 0
```

2.  Unmount all filesystems:

```
    cd /
    umount -a
```

3.  Create a temporary filesystem:

@FIXME /tmp may be a separate fs
```
    mkdir /tmp/tmproot
    mount -t tmpfs none /tmp/tmproot
    mkdir /tmp/tmproot/{proc,sys,usr,var,oldroot}
    cp -ax /{bin,etc,mnt,sbin,lib,lib64,run} /tmp/tmproot/
    cp -ax /usr/{bin,sbin,lib,lib64} /tmp/tmproot/usr/
    cp -ax /var/{account,empty,lib,local,lock,nis,opt,preserve,run,spool,tmp,yp} /tmp/tmproot/var/
    cp -a /dev /tmp/tmproot/dev
```

    _Note that this used up about 1.6GB of ramdisk on my Red Hat Enterprise Linux (AS) 4 server._

    _Also note that on 64-bit systems you will also need to copy `/lib64` and `/usr/lib64` as well,
    otherwise you will see errors like "lib64/ld-linux-x86-64.so.2: bad ELF interpreter: No such file or directory"_

4.  Switch the filesystem root to the temporary filesystem:

```
    pivot_root /tmp/tmproot/ /tmp/tmproot/oldroot
    mount none /proc -t proc
    mount none /sys -t sysfs _(this may fail on 2.4 systems)_
    mount none /dev/pts -t devpts
```

5.  Restart the SSH daemon to close the old pty devices:

```
    service sshd restart
```

    You should now try to make a new connection. If that succeeds, close your old one to release the old pty device.
    If it fails, get the SSH daemon properly restarted before proceeding.

6.  Close everything that's still using the old filesystem:

```
    umount /oldroot/proc
    umount /oldroot/dev/pts
    umount /oldroot/selinux
    umount /oldroot/sys
    umount /oldroot/var/lib/nfs/rpc_pipefs
```

    Now try to find other things that are still holding on to the old filesystem, particularly `/dev`:

```
    fuser -vm /oldroot/dev
```

    Common processes that will need killing:

```
    killall udevd
    killall gconfd-2
    killall mingetty
    killall minilogd
```

    Finally, you will need to re-execute `init`:

```
    telinit u
```

7.  Unmount the old filesystem:

```
    umount -l /oldroot/dev
    umount /oldroot
```

    Note that we use the `umount -l` ("lazy") option, available only with kernels 2.4.11 and later,
    because `/oldroot` is actually mounted using an entry in `/oldroot/dev`,
    so it would be difficult if not impossible to unmount either of them otherwise.

8.  Now resize the root filesystem:

```
    e2fsck -C 0 -f /dev/VolGroup00/LogVol00
    resize2fs -p -f /dev/VolGroup00/LogVol00 8G
    lvresize /dev/VolGroup00/LogVol00 -L 8G
    resize2fs -p -f /dev/VolGroup00/LogVol00
    e2fsck -C 0 -f /dev/VolGroup00/LogVol00
```

    In this example the root partition is `/dev/VolGroup00/LogVol00` and it is being shrunk to 8GB. You don't necessarily have to run `resize2fs` twice, I just do in case my idea of the size differs from what `lvresize` thinks.

9.  We're done, so start putting everything back:

```
    mount /dev/VolGroup00/LogVol00 /oldroot
    pivot_root /oldroot /oldroot/tmp/tmproot
    umount /tmp/tmproot/proc
    mount none /proc -t proc
    cp -ax /tmp/tmproot/dev/* /dev/
    mount /dev/pts
    mount /sys
    killall mingetty
    telinit u
    service sshd restart
```

    Now make a new SSH connection, and if it works, close the old one. Note that `sshd` may still be running in the temporary filesystem at this point because of the way the `service` scripts work - check this with `fuser`, and if this is the case, kill the oldest `sshd` process and then do `service sshd start`. Then log in again and disconnect all other connections.

    Final steps to unmount the temporary filesystem:

```
    umount -l /tmp/tmproot/dev/pts
    umount -l /tmp/tmproot
    rmdir /tmp/tmproot
```

    Now to re-mount our original filesystems and start services back up:

```
    mount -a
    umount /sys
    mount /sys
    for SERVICE in \
        $(chkconfig --list | grep 2:on | awk '{print $1}' | grep -v -e sshd -e network -e rawdevices); \
        do service $SERVICE start; done
    telinit 3
```

    Replace `3` with your preferred runlevel. _You may also want to start SELinux up again with `setenforce`._


The above has only been tested on RHEL AS 4, but something like it should work on most Linux variants
that have `pivot_root`, `tmpfs`, and `umount -l`, so long as you can replace the `chkconfig` and `service` parts
with whatever is appropriate for your distribution.

**Update:** [Lucas Chan](http://lucaschan.com/) says, for CentOS 4.4, "I was not able to login
after restarting `sshd` in step 5 until I did this: `mount none /dev/pts -t devpts`"

**Update:** [Simetrical](http://www.blogger.com/profile/09132743148689521886) suggests
that 64-bit systems also need to copy `/lib64` and `/usr/lib64`, and
that after `pivot_root` 2.6 kernels will also need `mount none /sys -t sysfs`
and `mount none /dev/pts -t devpts`. The above steps have been modified accordingly.

**Update:** nemo writes: "In my case, I had some trouble because `/run` wasn't copied.
This was a Debian squeeze, and `/var/run` only seems to be a symlink to `/run`"
