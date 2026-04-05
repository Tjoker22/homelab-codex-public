# Raspberry Pi 5 Rebuild

- rebuilding the raspberry pi 5 as a pi-hole dns and tailscale router to server ad-blocking to remote devices via tailscale.
- started by flashing pi os lite to a 256 gb ssd that is housed with the pi in a case. 
- will later move the pi unit to the server rack
- gained access to the pi via ssh to its temp dhcp ip address and ran a update and full-upgrade on teh system. 
- ran systemctl status dhcpcd and systemctl status NetworkManager to find which was active on the device. found NetworkManager was active so is set the static ip:
```bash
# Set the static IP
sudo nmcli con mod "Wired connection 1" \
  ipv4.method manual \
  ipv4.addresses 192.168.0.153/24 \
  ipv4.gateway 192.168.0.1 \
  ipv4.dns 127.0.0.1

# Bring the connection down and back up to apply
sudo nmcli con down "Wired connection 1" && sudo nmcli con up "Wired connection 1"
```

- reconnected to device at new ip address
- copied over ssh key from windows admin device to pi device and verified connection
	- working on securing ssh from wsl before moving on the the next step.
  - had to clear wsl ssh-keys and regenerate them. ssh login works now that the key was copied over to the pi
- when running the curl script for pi-hole, since we set the pi's dns to it's loopback, it could not resolve the web address to pull the installer.
  - ran the snippet to set dns to cloudflare 1.1.1.1 for the install. 
```bash
sudo nmcli con mod "Wired connection 1" ipv4.dns "1.1.1.1"
sudo nmcli con down "Wired connection 1" && sudo nmcli con up "Wired connection 1"
```
  - once the install is complete the dns will be set back to lopback
```bash
sudo nmcli con mod "Wired connection 1" ipv4.dns "127.0.0.1"
sudo nmcli con down "Wired connection 1" && sudo nmcli con up "Wired connection 1"
```
- went through the pi-hole installer, checked its status after install then changed the password for the webgui. 
  - webgui loads with no issues 
  - set my personal pc's dns to pihole to test before setting it on the house router.
  - added the following lists to the blocklist:
    - StevenBlack Unified | `https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts`
    - OISD Big | `https://big.oisd.nl/domainswild`
    - HaGeZi Multi Pro | `https://raw.githubusercontent.com/hagezi/dns-blocklists/main/adblock/pro.txt`
    - HaGeZi Threat Intel | `https://raw.githubusercontent.com/hagezi/dns-blocklists/main/adblock/tif.txt`
    - URLhaus Malware | `https://urlhaus-filter.pages.dev/urlhaus-filter-domains.txt`
  - found that after the gravity update for pi-hole ot add in the blocklists, i'm still getting adds laoding on webpage
  - first solution was to turn off secure dns in chrome settings
  - updated the dns on the router, gave it a few minutes before checking
    - if ads still appear i will manualy flush my pc's dns lease to force a refresh. can take up to 24 hours for all devices to refresh to pi-hole dns
  
