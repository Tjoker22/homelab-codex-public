# Project Helios Build

This is the build notes for the Project Helios build started on Monday April, 6 2026. 

# Build notes 

- f9 to pull boot menu and boot to the ventoy drive. installed debian 12 via non-graphical interface
- install ran easy: used the whole ssd on guided config with no split hoem/swap.
- de-selected any desktop environment and only installed ssh server and standard util tools.
- finished and rebooted, comes back u pand was able to log in at the console and also via ssh. 
- i will be working via ssh since it is availible  
- installed sudo and added user to sudo group, loggrd out of root and back to user. `sudo whoami` returned root 
- did a check to see with network mgmt was running on the device and found `networking` returned active
```bash
systemctl is-active networking
systemctl is-active NetworkManager 
```

- with networking being active, vim `/etc/network/interfaces` and replaced the dhcp block
```bash
auto <interface-name>
iface <interface-name> inet static
    address 192.168.0.151
    netmask 255.255.255.0
    gateway 192.168.0.1
    dns-nameservers 192.168.0.1
```

- applied the change followed by verifing the ip address
```bash
admin-yoyo@helios:~$ ip addr show eno1
2: eno1: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
    link/ether [MAC_REDACTED] brd [MAC_REDACTED]
    altname enp0s25
    altname enxe839353aa524
    inet 192.168.0.151/24 brd 192.168.0.255 scope global eno1
       valid_lft forever preferred_lft forever
    inet 192.168.0.73/24 brd 192.168.0.255 scope global secondary dynamic noprefixroute eno1
       valid_lft 7181sec preferred_lft 6281sec
    inet6 fe80::24ac:9f78:5940:e581/64 scope link
       valid_lft forever preferred_lft forever
```

- 192.168.0.151 is set staticly and always preferd but 192.168.0.73 is a secondary dynamic noprefixrpoute
- tested connectivity and all tests pass
 ```bash
ping -c 3 192.168.0.1     # gateway
ping -c 3 8.8.8.8         # internet
ping -c 3 google.com      # DNS resolution
```

```bash
admin-yoyo@helios:~$ ping -c 3 192.168.0.1
PING 192.168.0.1 (192.168.0.1) 56(84) bytes of data.
64 bytes from 192.168.0.1: icmp_seq=1 ttl=64 time=1.54 ms
64 bytes from 192.168.0.1: icmp_seq=2 ttl=64 time=0.840 ms
64 bytes from 192.168.0.1: icmp_seq=3 ttl=64 time=0.837 ms

--- 192.168.0.1 ping statistics ---
3 packets transmitted, 3 received, 0% packet loss, time 2014ms
rtt min/avg/max/mdev = 0.837/1.070/1.535/0.328 ms
admin-yoyo@helios:~$ ping -c 3 8.8.8.8
PING 8.8.8.8 (8.8.8.8) 56(84) bytes of data.
64 bytes from 8.8.8.8: icmp_seq=1 ttl=115 time=22.9 ms
64 bytes from 8.8.8.8: icmp_seq=2 ttl=115 time=29.1 ms
64 bytes from 8.8.8.8: icmp_seq=3 ttl=115 time=21.7 ms

--- 8.8.8.8 ping statistics ---
3 packets transmitted, 3 received, 0% packet loss, time 2003ms
rtt min/avg/max/mdev = 21.727/24.589/29.149/3.259 ms
admin-yoyo@helios:~$ ping -c 3 google.com
PING google.com (142.251.116.100) 56(84) bytes of data.
64 bytes from rt-in-f100.1e100.net (142.251.116.100): icmp_seq=1 ttl=104 time=24.6 ms
64 bytes from rt-in-f100.1e100.net (142.251.116.100): icmp_seq=2 ttl=104 time=22.6 ms
64 bytes from rt-in-f100.1e100.net (142.251.116.100): icmp_seq=3 ttl=104 time=26.7 ms

--- google.com ping statistics ---
3 packets transmitted, 3 received, 0% packet loss, time 2003ms
rtt min/avg/max/mdev = 22.572/24.638/26.730/1.697 ms
```
- recored mac address and update registers: [MAC_REDACTED]
- copied over my main admin pcs ssh keys
    - will disable the password auth after adding other admin machines keys using the following
```bash
sudo sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
sudo systemctl restart sshd
``` 
- finalized initial install and asetup wtih setting the hostname to `helios` and verifying
```bash
admin-yoyo@helios:~$ sudo hostnamectl set-hostname helios
[sudo] password for admin-yoyo:
admin-yoyo@helios:~$ cat /etc/hosts
127.0.0.1       localhost
127.0.1.1       helios

# The following lines are desirable for IPv6 capable hosts
::1     localhost ip6-localhost ip6-loopback
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
```

- had to make an update to the build guide to account for installing debin 13 trixie over debian 12 bookworm. 
- added the `contrib` component to the `/etc/apt/sources.list` then added trixie-backports.list and pined zfs to come from the backports:
```bash
sudo tee /etc/apt/sources.list.d/trixie-backports.list > /dev/null << 'EOF'
deb http://deb.debian.org/debian trixie-backports main contrib non-free-firmware
deb-src http://deb.debian.org/debian trixie-backports main contrib non-free-firmware
EOF
```
```bash
sudo tee /etc/apt/preferences.d/90_zfs > /dev/null << 'EOF'
Package: src:zfs-linux
Pin: release n=trixie-backports
Pin-Priority: 990
EOF
```

- verification
```bash
admin-yoyo@helios:~$ cat /etc/apt/sources.list.d/trixie-backports.list
deb http://deb.debian.org/debian trixie-backports main contrib non-free-firmware
deb-src http://deb.debian.org/debian trixie-backports main contrib non-free-firmware
admin-yoyo@helios:~$ cat /etc/apt/preferences.d/90_zfs
Package: src:zfs-linux
Pin: release n=trixie-backports
Pin-Priority: 990
```

- moved to installing zfs kernal headers and build tools followed by installing zfs and zfs-utisl
```bash
sudo apt install -y dpkg-dev linux-headers-amd64
sudo apt install -y zfs-dkms zfsutils-linux
```

- loaded the afs module and verified along with the `zpool status` which returned no pools available which is expected
- also checked and verified the linux headers matched which they did
- moved to indentifying the storage drives stable paths to use for setting up the zpool
- `ls -la /dev/disk/by-id/ | grep -v part`
```bash
total 0
drwxr-xr-x 2 root root 400 Apr  6 09:18 .
drwxr-xr-x 9 root root 180 Apr  6 09:18 ..
lrwxrwxrwx 1 root root   9 Apr  6 09:18 ata-HGST_HTS725050A7E630_RC250ACB0MPZRJ -> ../../sdd
lrwxrwxrwx 1 root root   9 Apr  6 09:18 ata-HGST_HTS725050A7E630_RC250ACB0N23RJ -> ../../sdc
lrwxrwxrwx 1 root root   9 Apr  6 09:18 ata-HGST_HTS725050A7E630_RC250ACB0NNSXJ -> ../../sda
lrwxrwxrwx 1 root root   9 Apr  6 09:18 ata-LITEON_LCH-256V2S-HP_002537168805 -> ../../sdb
```

- set up the zpool create snipet 
```bash
sudo zpool create heliospool raidz1 \
  /dev/disk/by-id/ata-HGST_HTS725050A7E630_RC250ACB0NNSXJ \
  /dev/disk/by-id/ata-HGST_HTS725050A7E630_RC250ACB0N23RJ \
  /dev/disk/by-id/ata-HGST_HTS725050A7E630_RC250ACB0MPZRJ
```

- enabled lz4 compression and set dataset mountpoints
```bash
sudo zfs create -o mountpoint=/srv/forgejo heliospool/forgejo
sudo zfs create -o mountpoint=/srv/samba/shared heliospool/shared
sudo zfs create -o mountpoint=/srv/samba/media heliospool/media
sudo zfs create -o mountpoint=/srv/backups heliospool/backups
```

- verified
```bash
admin-yoyo@helios:~$ sudo zpool status heliospool
  pool: heliospool
 state: ONLINE
config:

        NAME                                         STATE     READ WRITE CKSUM
        heliospool                                   ONLINE       0     0     0
          raidz1-0                                   ONLINE       0     0     0
            ata-HGST_HTS725050A7E630_RC250ACB0NNSXJ  ONLINE       0     0     0
            ata-HGST_HTS725050A7E630_RC250ACB0N23RJ  ONLINE       0     0     0
            ata-HGST_HTS725050A7E630_RC250ACB0MPZRJ  ONLINE       0     0     0

errors: No known data errors

admin-yoyo@helios:~$ sudo zfs list
NAME                 USED  AVAIL  REFER  MOUNTPOINT
heliospool          1.17M   898G   128K  /heliospool
heliospool/backups   128K   898G   128K  /srv/backups
heliospool/forgejo   128K   898G   128K  /srv/forgejo
heliospool/media     128K   898G   128K  /srv/samba/media
heliospool/shared    128K   898G   128K  /srv/samba/shared

admin-yoyo@helios:~$ df -h /srv/forgejo /srv/samba/shared /srv/samba/media /srv/backups
Filesystem          Size  Used Avail Use% Mounted on
heliospool/forgejo  899G  128K  899G   1% /srv/forgejo
heliospool/shared   899G  128K  899G   1% /srv/samba/shared
heliospool/media    899G  128K  899G   1% /srv/samba/media
heliospool/backups  899G  128K  899G   1% /srv/backups
```


## Ideas moving forward

- 

## Ideas to resolve

- 
