# Raspberry Pi 5 Rebuild (project-hestia-build)

## Build notes

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
  
- installed Tailscale and approved it in the web admin consol. 
  - wokring on enabling ip forwarding to advirtise the subnet but at the moment the subnet isnt being advertised. used the follwoing commands 
```bash
echo 'net.ipv4.ip_forward = 1' | sudo tee -a /etc/sysctl.d/99-tailscale.conf
echo 'net.ipv6.conf.all.forwarding = 1' | sudo tee -a /etc/sysctl.d/99-tailscale.conf
sudo sysctl -p /etc/sysctl.d/99-tailscale.conf
```
  - tailscale status and tailscale ip both return ip address but no connected status while the web ui shows a connection
```bash
admin-yoyo@hestia:~ $ tailscale status
100.64.195.26   hestia                  [USERNAME]@  linux    -
                ("")                    -                   offline
100.75.253.106  alival                  [USERNAME]@  windows  offline, last seen 34d ago
100.119.62.61   fedora                  [USERNAME]@  linux    offline, last seen 10d ago
100.81.172.30   ipad-pro-12-9-gen-3     [USERNAME]@  iOS      offline, last seen 16d ago
100.83.104.10   iphone-13-pro-max       [USERNAME]@  iOS      offline, last seen 15d ago
100.99.237.105  wilhelms-macbook-pro-1  [USERNAME]@  macOS    offline, last seen 110d ago
100.117.224.94  wilhelms-macbook-pro-2  [USERNAME]@  macOS    offline, last seen 110d ago
100.65.129.116  wilhelms-macbook-pro    [USERNAME]@  macOS    offline, last seen 55d ago
admin-yoyo@hestia:~ $ tailscale ip
100.64.195.26
fd7a:115c:a1e0::1339:c31a
```
  - giving the following a try as the system may not be using sysctl.d
```bash
echo 'net.ipv4.ip_forward = 1' | sudo tee -a /etc/sysctl.conf
echo 'net.ipv6.conf.all.forwarding = 1' | sudo tee -a /etc/sysctl.conf
sudo sysctl -p /etc/sysctl.conf
```
    - this snippet worked in properly advertising the subnet and it has been approved on the web admin ui

- did a check on all running services on the device and both returned active and running.
```bash
admin-yoyo@hestia:~ $ sudo systemctl status pihole-FTL      # Pi-hole DNS
● pihole-FTL.service - Pi-hole FTL
     Loaded: loaded (/etc/systemd/system/pihole-FTL.service; enabled; preset: enabled)
     Active: active (running) since Mon 2026-03-30 18:09:37 CDT; 6 days ago
 Invocation: 4a8ba5d558f24ab386a07886f9f207b8
   Main PID: 22163 (pihole-FTL)
      Tasks: 25 (limit: 9573)
        CPU: 12min 32.662s
     CGroup: /system.slice/pihole-FTL.service
             └─22163 /usr/bin/pihole-FTL -f
admin-yoyo@hestia:~ $ sudo systemctl status tailscaled      # Tailscale

● tailscaled.service - Tailscale node agent
     Loaded: loaded (/usr/lib/systemd/system/tailscaled.service; enabled; preset: enabled)
     Active: active (running) since Sun 2026-04-05 21:59:58 CDT; 25min ago
 Invocation: f3bb4ac7e7f6462fa1dd2d2dc98fa58d
       Docs: https://tailscale.com/docs/
   Main PID: 31598 (tailscaled)
     Status: "Connected; [USERNAME]@github; 100.64.195.26 fd7a:115c:a1e0::1339:c31a"
      Tasks: 12 (limit: 9573)
        CPU: 1.732s
     CGroup: /system.slice/tailscaled.service
             └─31598 /usr/sbin/tailscaled --state=/var/lib/tailscale/tailscaled.state --socket=/run/tailscale/tailscale>
```
- enabled start on boot for pi-hole and tailscale
```bash
sudo systemctl enable pihole-FTL
sudo systemctl enable tailscaled
```
  - both services started adn run follwoing a reboot test.

## Ideas moving forward

- look at installing a monitoring scraper to report back to Eos monitoring

## Issues to resolve

- at the moment pi-hole is blocking ads via wi-fi but not much via hardline ethernet connection.
- look at way to clean the sysctl.d commands for enabling subnet advertizing
```bash
echo 'net.ipv4.ip_forward = 1' | sudo tee -a /etc/sysctl.d/99-tailscale.conf
echo 'net.ipv6.conf.all.forwarding = 1' | sudo tee -a /etc/sysctl.d/99-tailscale.conf
sudo sysctl -p /etc/sysctl.d/99-tailscale.conf
```
 