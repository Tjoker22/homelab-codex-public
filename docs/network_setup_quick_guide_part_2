**Phase 1 Maintenance Window — Full Order of Operations**

---

**Pre-Window Prep — Do These Before the Maintenance Window**

These are all safe on a live network and require no disruption.

```
☐  1. Set OC200 controller IP to 192.168.99.2
       Controller restarts — reconnect at https://192.168.99.2:8043
       Confirm login works at new address before proceeding

☐  2. Set TL-SG2008P management IP
       Devices → SG2008P → Config → Advanced
       IP: 192.168.99.10 / Mask: 255.255.255.0 / GW: 192.168.99.1 / VLAN: 99

☐  3. Create port profiles in Omada
       Settings → Profiles → Switch Profiles
       HOME      — untagged VLAN 10 / native VLAN 10
       MGMT      — untagged VLAN 99 / native VLAN 99
       TRUNK-ALL — tagged VLANs 10,20,30,99 / native VLAN 99
       LAN-Uplink — untagged VLAN 10 / native VLAN 10

☐  4. Fix Raspberry Pi static IP
       KVM into Pi
       sudo nano /etc/dhcpcd.conf
       Remove or comment out the static IP block:
         #interface eth0
         #static ip_address=x.x.x.x/24
         #static routers=x.x.x.1
         #static domain_name_servers=x.x.x.x
       Save and reboot
       Confirm Pi comes back up on its current flat address
       KVM session stays open — you will need it during the window

☐  5. Pre-flight notes — write these down before starting the window
       OC200 new dashboard URL:  https://192.168.99.2:8043
       Omada login credentials:  [username / password]
       Admin PC reservation:     192.168.10.10
       Admin Laptop reservation: 192.168.10.11
       Pi reservation:           192.168.10.15
```

---

**Maintenance Window — Start Here**

> Inform household that the network will have brief interruptions.  
> Keep the Admin Laptop on Wi-Fi connected throughout — it is your backup admin console.  
> Do not move to the next step until the current step is verified.

---

**Step 1 — Media Devices (TV, PS5)**

```
Action:
  Change each device's port to HOME profile — one at a time
  Wait 60 seconds after each port change

Verify after each device:
  ☐  Device shows a 192.168.10.x address in Omada → Clients
  ☐  Internet works on the device — load something
  ☐  No other devices lost connectivity

If a device does not get a new IP after 60 seconds:
  → Power cycle the device
  → Wait another 60 seconds
  → Check Omada Clients page for the new lease
```

---

**Step 2 — Remaining Home Devices**

```
Action:
  Change remaining device ports to HOME profile — one at a time
  Any device you are unsure about — change it, verify, then move on

Verify after each:
  ☐  Device shows 192.168.10.x address
  ☐  Internet works
  ☐  No unexpected devices lost connectivity
```

---

**Step 3 — EAP Port → HOME Profile**

```
Action:
  Change the EAP's port on the SG2008P to HOME profile

What happens automatically:
  Admin Laptop (Wi-Fi) gets a new DHCP lease on VLAN 10
  Any other wireless clients reconnect on VLAN 10

Verify:
  ☐  Admin Laptop shows 192.168.10.11 — check network settings
  ☐  Internet works on Admin Laptop
  ☐  Other wireless devices show 192.168.10.x addresses
  ☐  Omada dashboard still accessible from Admin Laptop
       https://192.168.99.2:8043
  ☐  Omada Clients page shows wireless devices on VLAN 10

  ★  Admin Laptop is now your confirmed backup admin console
     Keep it connected to Wi-Fi for the rest of the window
```

---

**Step 4 — Update Pi-hole DNS in Omada**

```
Action:
  Settings → Wired Networks → LAN → HOME (VLAN 10)
  Change DNS Primary from 1.1.1.1 to 192.168.10.15

  Note: Pi is not yet on VLAN 10 — this update takes effect
  after the shared port changes in Step 5. Safe to set now.

Verify:
  ☐  DNS entry saved as 192.168.10.15 in VLAN 10 config
```

---

**Step 5 — Shared Port (Admin PC + Raspberry Pi) → HOME Profile**

```
Action:
  Change the shared unmanaged switch port to HOME profile
  Both Admin PC and Pi move simultaneously

What happens:
  Admin PC  → requests DHCP lease → gets 192.168.10.10 (reservation)
  Pi        → requests DHCP lease → gets 192.168.10.15 (reservation)

Verify Admin PC:
  ☐  Admin PC shows 192.168.10.10 — check network settings
       Windows: ipconfig in terminal
  ☐  Internet works from Admin PC
  ☐  Can reach Omada dashboard from Admin PC
       https://192.168.99.2:8043

Verify Pi via KVM:
  ☐  Pi shows 192.168.10.15
       hostname -I  or  ip addr show eth0
  ☐  Pi-hole admin page loads
       http://192.168.10.15/admin
  ☐  Pi-hole query log shows DNS activity from home devices
       Pi-hole admin → Query Log — should see entries populating

If Admin PC gets wrong IP:
  → Run ipconfig /release then ipconfig /renew
  → If still wrong — Admin Laptop is your backup, continue from there

If Pi gets wrong IP:
  → KVM into Pi — run sudo dhclient -r then sudo dhclient
  → If still wrong — check reservation MAC matches exactly
```

---

**Step 6 — OC200 Port → MGMT Profile**

```
This is the point of no return for dashboard access on the
current connection. Have the Admin Laptop ready before proceeding.

Pre-flight — confirm all of these before touching Port 1:
  ☐  Admin Laptop confirmed on 192.168.10.11 with internet
  ☐  Admin PC confirmed on 192.168.10.10 with internet
  ☐  Pi confirmed on 192.168.10.15 with Pi-hole working
  ☐  Dashboard URL noted: https://192.168.99.2:8043
  ☐  Login credentials confirmed

Action:
  Change Port 1 (OC200) to MGMT profile
  Dashboard goes offline immediately — this is expected

Reconnect:
  From Admin Laptop or Admin PC open a new browser tab
  Go to https://192.168.99.2:8043
  Accept the certificate warning
  Log in

Verify:
  ☐  Dashboard loads at https://192.168.99.2:8043
  ☐  All devices show as adopted — no pending or disconnected
  ☐  Omada Clients page shows all devices on correct VLANs
  ☐  SG2008P shows online in Devices
  ☐  ER605 shows online in Devices
  ☐  EAP shows online in Devices
```

---

**Phase 1 Complete — Final Verification**

```
Run through every item before closing the maintenance window:

Network:
  ☐  Every home device has a 192.168.10.x address
  ☐  Internet works on all devices — wired and wireless
  ☐  No devices stuck on old flat network addresses

Pi-hole:
  ☐  Pi at 192.168.10.15 — confirmed via KVM
  ☐  Pi-hole admin accessible at http://192.168.10.15/admin
  ☐  Query log shows active DNS traffic from home devices
  ☐  VLAN 10 DNS set to 192.168.10.15 in Omada

Admin access:
  ☐  Omada dashboard accessible at https://192.168.99.2:8043
  ☐  Admin PC reaches dashboard — 192.168.10.10 confirmed
  ☐  Admin Laptop reaches dashboard — 192.168.10.11 confirmed

Omada:
  ☐  All devices adopted and showing online
  ☐  No alerts or warnings in dashboard

Documentation:
  ☐  Change log entries completed in register for every port change
  ☐  Screenshot of Omada Clients page — all devices on VLAN 10
  ☐  Screenshot of port assignments in Omada
  ☐  Phase 1 checklist marked complete in NDD and register
```

---

**If Something Goes Wrong**

```
Lost dashboard access unexpectedly:
  → Try https://192.168.99.2:8043 from Admin Laptop on Wi-Fi
  → Try https://192.168.99.2:8043 from Admin PC
  → If neither works — OC200 may need port moved back temporarily

Device stuck on wrong IP:
  → Windows: ipconfig /release then ipconfig /renew
  → Linux/Pi: sudo dhclient -r then sudo dhclient
  → Last resort: power cycle the device

Pi-hole not receiving queries after DNS update:
  → Confirm Pi is at 192.168.10.15 via KVM
  → Check VLAN 10 DNS in Omada still shows 192.168.10.15
  → Restart DNS resolver on Pi: pihole restartdns

Any port change causes unexpected outage:
  → Change the port back to its previous profile immediately
  → Diagnose from Admin Laptop before retrying
  → Do not proceed to next step until current step is resolved
```