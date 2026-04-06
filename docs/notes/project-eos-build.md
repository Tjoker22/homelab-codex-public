# Project Eos Build

This is the build notes for the pProject Eos build started on Sunday April, 5 2026. 

## Build notes

- clean install to target pc nvme01 (256Gb nvme for OS)
- diabled both enterprise and ceph-enterprise repos and added the no-subcription versions of the repo. 
- running `apt upadte && apt full-upgrade -y` follwoed by a reboot when done 
- verified hosts:
```bash
cat /etc/hosts
```
 - returned:
``` bash 
127.0.0.1 localhost.localdomain localhost
192.168.0.154 eos.local eos
```

- checked for the hdd stable path and created zpool with the 1 tb hdd. will later be mirrored with a second 1 tb drive added
```bash
ls -la /dev/disk/by-id/ | grep -v part
```

```bash
zpool create -f \
  -o ashift=12 \
  eospool \
  /dev/disk/by-id/<your-hdd-id>
```

- verified the zpool:
```bash
root@eos:~# zpool status eospool 
  pool: eospool
 state: ONLINE
config:

        NAME                                STATE     READ WRITE CKSUM
        eospool                             ONLINE       0     0     0
          ata-TOSHIBA_DT01ACA100_103N7AKMS  ONLINE       0     0     0

errors: No known data errors
```

```bash
root@eos:~# zpool list 
NAME      SIZE  ALLOC   FREE  CKPOINT  EXPANDSZ   FRAG    CAP  DEDUP    HEALTH  ALTROOT
eospool   928G   396K   928G        -         -     0%     0%  1.00x    ONLINE  -
```

- Set zfs compressioin and created container mount points for general purpose and nextcloud
 - nextcloud mountpoint dreated as planned but can be removed if plans change for nextcloude to be hosted on a differnet device.
```bash
zfs set compression=lz4 eospool

zfs create -o mountpoint=/eospool/data eospool/data

zfs create -o mountpoint=/eospool/nextcloud eospool/nextcloud
```

- verified:
```bash
root@eos:~# zfs list
NAME                USED  AVAIL  REFER  MOUNTPOINT
eospool             644K   899G   104K  /eospool
eospool/data         96K   899G    96K  /eospool/data
eospool/nextcloud    96K   899G    96K  /eospool/nextcloud
root@eos:~# df -h /eospool/data/
Filesystem      Size  Used Avail Use% Mounted on
eospool/data    900G  128K  900G   1% /eospool/data
```

- added the pool to the web ui with the naem `eospool`

## Ideas moving forward

## Ideas to resolve