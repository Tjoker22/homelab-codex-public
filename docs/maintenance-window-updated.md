# JXStudios — Updated Maintenance Window Procedure
**Site:** JXStudios  
**Updated:** 22/03/2026  
**Reason for update:** Cross-referenced against official Omada support documentation. Corrections applied for OC200 MGMT migration, Discovery Utility requirement, v6 UI path changes. All OS instructions included — Windows, Mac, Linux.  
**Controller firmware:** 6.2.0.122.24.6 Build 20260227 Rel.85612 (Omada Network v6)

---

## ⚠️ Credentials — Write These Down On Paper Now

Do this before anything else. Do not rely on digital access — you may lose network connectivity during the window.

| Item | Value |
|------|-------|
| Omada dashboard URL | https://192.168.99.2:8043 |
| Omada local username | `[your chosen username]` |
| Omada local password | `[your chosen password]` |
| ER605 device account username | `[write this down — needed for Discovery Utility]` |
| ER605 device account password | `[write this down — needed for Discovery Utility]` |
| Admin PC reserved IP | 192.168.10.10 |
| Admin Laptop reserved IP | 192.168.10.11 |
| Pi-hole reserved IP | 192.168.10.15 |
| Pi-hole admin page | http://192.168.10.15/admin |
| OC200 reserved IP | 192.168.99.2 |
| SG2008P management IP | 192.168.99.10 |
| Emergency direct access | https://192.168.99.2:8043 via patch cable to OC200 ETH2 |
| Emergency laptop static IP | 192.168.99.10/24 — GW 192.168.99.2 |

> **ER605 device account:** found in Omada → Settings → Site → Device Account.  
> Write these down before the window — the dashboard will go offline during Step 7 Part A and you will not be able to retrieve them.

---

## Pre-Window Prep — Updated Checklist

> Complete ALL items below before the maintenance window begins.  
> Items marked ✅ were already done. Items marked ☐ are new or revised requirements.

### Already Complete
- ✅ VLANs 10, 20, 30, 99 created on ER605
- ✅ DHCP pools configured per VLAN
- ✅ DHCP reservations set — Admin PC, Admin Laptop, Xavier PC, Pi-hole, OC200
- ✅ 7 Gateway ACL rules created and enabled
- ✅ IP Groups created — all 5
- ✅ OC200 reset and config restored
- ✅ Port profiles created — HOME, MGMT, TRUNK-ALL, LAN-Uplink
- ✅ Raspberry Pi static IP removed — Pi back up on DHCP
- ✅ Fresh config backup saved to Git repo

---

### NEW — Required Before Window Day

#### 1. Download and Install Discovery Utility (Admin Laptop)

This step is **required** per official Omada documentation. Without it, the ER605 will not know the OC200 has moved to a new IP, and devices may show disconnected after the cutover even if the OC200 is healthy.

**Download page:**  
https://support.omadanetworks.com/us/download/software/omada-discovery-utility/

Current version: **5.2.4** (released 06-16-2025, 56 MB)

---

**Step 1a — Install Java 17 (required by Discovery Utility 5.2.4):**

*Windows:*
```
1. Go to: https://www.oracle.com/java/technologies/downloads/#java17-windows
2. Download: Windows x64 Installer (.exe)
3. Run the installer — accept defaults
4. Verify: open Command Prompt → type:
     java -version
   Should show: java version "17.x.x"
```

*macOS:*
```
Discovery Utility on Mac requires Zulu JDK 17 FX — not standard Java 17.

1. Go to: https://www.azul.com/downloads/?version=java-17-lts&os=macos&package=jdk-fx
2. Download the .dmg for your architecture:
     Intel Mac      → x86 64-bit
     Apple Silicon  → ARM 64-bit
3. Install the .dmg — follow the prompts
4. Verify: open Terminal → type:
     java -version
   Should show: openjdk version "17.x.x" (Zulu)
```

*Linux — Fedora / RHEL-based:*
```bash
sudo dnf install java-17-openjdk

# Verify
java -version
# Should show: openjdk version "17.x.x"
```

*Linux — Debian / Ubuntu-based:*
```bash
sudo apt update
sudo apt install openjdk-17-jre

# Verify
java -version
```

---

**Step 1b — Install and test the Discovery Utility:**

*Windows:*
```
1. Download and unzip the Discovery Utility zip file
2. Double-click: start-discovery-utility-windows.bat
3. Confirm the utility home page loads
4. Devices on your network should appear in the list
5. Close it — ready for window day
```

*macOS:*
```
1. Download and unzip the Discovery Utility zip file
2. Open Terminal and cd into the unzipped folder:
     cd ~/Downloads/omada-discovery-utility-5.2.4/
3. Run:
     java --enable-native-access=ALL-UNNAMED -jar omada-discovery-utility-5.2.4.jar
4. Confirm the utility home page loads
5. Close it — ready for window day
```

*Linux:*
```bash
# Download and unzip
unzip omada-discovery-utility-5.2.4.zip
cd omada-discovery-utility-5.2.4/

# Make launch script executable
chmod +x start-discovery-utility-linux.sh

# Launch
./start-discovery-utility-linux.sh

# Confirm the home page loads — devices should appear
# Close it — ready for window day
```

> **Do this before window day.** You do not want to be troubleshooting Java installs during a network cutover.

> **Note:** The Discovery Utility cannot run on the same machine as an Omada Software Controller. Since you are using the OC200 hardware controller, this is not a concern — run the utility freely from any machine on the network.

---

#### 2. Fix the OC200 DHCP Reservation — MGMT VLAN Field

> ⚠️ This is the most likely cause of the previous window failure.

The OC200 reservation must be set with the **Network field pointing to MGMT VLAN 99**, not the default LAN. If it was set under the wrong network, the OC200 will not receive 192.168.99.2 when it moves to the MGMT port.

**Verify and correct the reservation (v6 UI path):**

```
Clients → find OC200 in client list → Manage Client → Config tab
  → check "Use Fixed IP Address"
  → Network: select MGMT (VLAN 99)   ← CRITICAL — must be MGMT, not default LAN
  → IP Reserved Address: 192.168.99.2
  → Save

Verify at: Network Config → DHCP Reservation
  Confirm OC200 appears with IP 192.168.99.2 under the MGMT network
```

> **Note:** Firmware 6.2.0 is well above version 5.0.29, so reserved IPs are not required to fall within the DHCP pool range. You do not need to temporarily enable a DHCP pool on MGMT — the reservation will be honoured regardless of pool boundaries.

---

#### 3. Enable Auto Refresh IP on OC200

> ⚠️ Also missing from the previous procedure. Without this, the OC200 will not automatically request a new DHCP lease when moved to the MGMT port — it may hold its old IP until the lease expires naturally.

```
Devices → click OC200 to open sidebar → Config → Services
  → Enable: Auto Refresh IP  ← toggle ON
  → Save / Apply
```

---

#### 4. Verify All Reservations Are on Correct Networks

While in the client reservation flow, confirm each reservation has the correct Network field:

```
Clients → Manage Client → Config → Use Fixed IP Address

| Device       | Network field must show | Reserved IP   |
|--------------|------------------------|---------------|
| Admin PC     | HOME (VLAN 10)         | 192.168.10.10 |
| Admin Laptop | HOME (VLAN 10)         | 192.168.10.11 |
| Xavier PC    | HOME (VLAN 10)         | 192.168.10.12 |
| Pi-hole      | HOME (VLAN 10)         | 192.168.10.15 |
| OC200        | MGMT (VLAN 99)         | 192.168.99.2  |
```

Verify all entries at: **Network Config → DHCP Reservation**

---

#### 5. Note Down ER605 Device Account Credentials

Before the window, go to **Settings → Site → Device Account** and write the username and password on paper. These are required for the Discovery Utility Batch Setting in Step 7 Part B, and the dashboard will be offline at that point.

---

#### 6. Write All Credentials on Paper

See the credentials table at the top of this document. Do not skip this.

---

## Maintenance Window — Full Order of Operations (Updated)

> Inform household of planned disruption before starting.  
> Keep Admin Laptop on Wi-Fi throughout — it is your backup admin console.  
> One port at a time. Verify before moving to the next step.  
> Do not begin a step until the previous step is fully verified.

---

### Step 1 — Media Devices (TV, PS5)

```
Where: Devices → SG2008P → Ports → Port Settings

Action:
  Change each media device port to HOME profile — one at a time
  Wait 60 seconds after each change

Verify after each device:
  ☐  Device shows 192.168.10.x in Omada → Clients
  ☐  Internet works on the device
  ☐  No other devices lost connectivity

If device does not get new IP after 60 seconds:
  → Power cycle the device → wait 60 seconds → check Clients
```

---

### Step 2 — Remaining Home Devices

```
Action:
  Change remaining home device ports to HOME profile — one at a time

Verify after each:
  ☐  Device shows 192.168.10.x address
  ☐  Internet works
  ☐  No unexpected devices lost connectivity
```

---

### Step 3 — EAP Port → HOME Profile

```
Action:
  Change EAP port on SG2008P to HOME profile

What happens automatically:
  Admin Laptop (Wi-Fi) gets DHCP lease on VLAN 10 → 192.168.10.11
  All wireless clients reconnect on VLAN 10

Verify Admin Laptop IP:

  Windows:
    Open Command Prompt → type: ipconfig
    Look for IPv4 Address: 192.168.10.11 under the Wi-Fi adapter
    Or: Settings → Network & Internet → Wi-Fi → [network name] → Properties

  macOS:
    System Settings → Wi-Fi → Details → IP Address
    Or: open Terminal → type: ipconfig getifaddr en0
    Should show: 192.168.10.11

  Linux:
    ip addr show [wifi interface]
    Or: nmcli device show [interface] | grep IP4.ADDRESS
    Should show: 192.168.10.11/24

Verify:
  ☐  Admin Laptop shows 192.168.10.11
  ☐  Internet works on Admin Laptop
  ☐  Omada dashboard still reachable from Admin Laptop
  ☐  Other wireless devices show 192.168.10.x

  ★  Admin Laptop is now your confirmed backup admin console
     Keep it on Wi-Fi for the rest of the window
```

---

### Step 4 — Update Pi-hole DNS in Omada

```
Where (v6 UI): Network Config → LAN → HOME (VLAN 10) → edit → DNS

Action:
  Change DNS Primary from 1.1.1.1 to 192.168.10.15
  Save

Note: Pi is not yet on VLAN 10 at this point — takes effect after Step 5.

Verify:
  ☐  DNS entry saved as 192.168.10.15 in VLAN 10 config
```

---

### Step 5 — Shared Port (Admin PC + Raspberry Pi) → HOME Profile

```
Note: Admin PC and Pi share one port via an unmanaged switch.
Both devices move simultaneously when this port changes.

Action:
  Change the shared unmanaged switch port to HOME profile

What happens:
  Admin PC  → DHCP → 192.168.10.10 (reservation)
  Pi        → DHCP → 192.168.10.15 (reservation)

Verify Admin PC IP:

  Windows:
    Open Command Prompt → ipconfig
    Look for IPv4 Address: 192.168.10.10 under the ethernet adapter
    ☐  Shows 192.168.10.10

  macOS:
    System Settings → Network → ethernet adapter → IP Address
    Or: open Terminal → ipconfig getifaddr en0
    ☐  Shows 192.168.10.10

  Linux:
    ip addr show [ethernet interface]
    Or: nmcli device show [interface] | grep IP4.ADDRESS
    ☐  Shows 192.168.10.10/24

Verify Admin PC connectivity:
  ☐  Internet works from Admin PC
  ☐  Omada dashboard reachable from Admin PC

Verify Pi via KVM or monitor:
  Run on Pi: hostname -I
  ☐  Shows 192.168.10.15
  ☐  Pi-hole admin loads: http://192.168.10.15/admin
  ☐  Pi-hole query log shows DNS activity

If Admin PC gets wrong IP:

  Windows:
    ipconfig /release
    ipconfig /renew

  macOS:
    System Settings → Network → ethernet → Renew DHCP Lease
    Or: open Terminal → sudo ipconfig set en0 DHCP

  Linux:
    sudo dhclient -r [interface]
    sudo dhclient [interface]
    With NetworkManager:
      nmcli device disconnect [interface]
      nmcli device connect [interface]

  If still wrong on any OS — use Admin Laptop as primary and continue

If Pi gets wrong IP:
  sudo dhclient -r && sudo dhclient
  Verify reservation MAC matches: [MAC_REDACTED]
```

---

### Step 6 — SG2008P Management VLAN → 99

```
Where (v6 UI): Devices → SG2008P → Config → Management VLAN
               Set to: VLAN 99 → Apply

Verify:
  ☐  Switch still shows Connected in Omada Devices
  ☐  Switch config still accessible
```

---

### Step 7 — OC200 Port → MGMT Profile + Discovery Utility (Point of No Return)

> This is a three-part step. Do not skip Part B — it is required by official Omada documentation.

**Pre-flight — confirm ALL of these before touching Port 1:**

```
  ☐  Admin Laptop confirmed 192.168.10.11 with internet (Wi-Fi)
  ☐  Admin PC confirmed 192.168.10.10 with internet (wired)
  ☐  Pi confirmed 192.168.10.15 — Pi-hole admin page loading
  ☐  SG2008P management VLAN confirmed on 99 (Step 6 complete)
  ☐  OC200 Auto Refresh IP is enabled (pre-window prep item 3)
  ☐  OC200 reservation set to MGMT VLAN 99 → 192.168.99.2 (pre-window prep item 2)
  ☐  Discovery Utility installed and tested on Admin Laptop (pre-window prep item 1)
  ☐  ER605 device account credentials written on paper
  ☐  Dashboard URL on paper: https://192.168.99.2:8043
  ☐  Omada login credentials on paper
```

---

**Part A — Move OC200 to MGMT:**

```
Action:
  Devices → SG2008P → Ports → Port 1 → change profile to MGMT
  Apply / Save

What happens:
  Dashboard goes offline immediately — expected
  OC200 releases its current IP and requests a new DHCP lease
  Auto Refresh IP triggers the renewal automatically
  OC200 picks up 192.168.99.2 from the MGMT VLAN reservation

Wait 60–90 seconds before proceeding to Part B
```

---

**Part B — Run Discovery Utility to update the ER605 (REQUIRED):**

```
Why this is needed:
  The ER605 still points to the OC200's old IP address.
  Without this step, the gateway cannot locate the controller
  and adopted devices may show as disconnected even though
  the OC200 is healthy and reachable at 192.168.99.2.
```

*Windows:*
```
1. Double-click: start-discovery-utility-windows.bat
2. Wait for devices to appear in the list
3. Locate and select the ER605
4. Click "Batch Setting"
5. Fill in:
     Controller Hostname/IP: 192.168.99.2
     Username: [ER605 device account username — from paper]
     Password: [ER605 device account password — from paper]
6. Click Apply
7. Close the utility
```

*macOS:*
```
1. Open Terminal — cd to the Discovery Utility folder
2. Run:
     java --enable-native-access=ALL-UNNAMED -jar omada-discovery-utility-5.2.4.jar
3. Wait for devices to appear — locate the ER605
4. Select the ER605 → click "Batch Setting"
5. Fill in:
     Controller Hostname/IP: 192.168.99.2
     Username: [ER605 device account username — from paper]
     Password: [ER605 device account password — from paper]
6. Click Apply
7. Close the utility
```

*Linux:*
```bash
cd omada-discovery-utility-5.2.4/
./start-discovery-utility-linux.sh

# In the utility UI:
# 1. Wait for devices to appear — locate the ER605
# 2. Select the ER605 → click "Batch Setting"
# 3. Fill in:
#      Controller Hostname/IP: 192.168.99.2
#      Username: [ER605 device account username — from paper]
#      Password: [ER605 device account password — from paper]
# 4. Click Apply
# 5. Close the utility
```

---

**Part C — Reconnect to dashboard:**

```
Open a new browser tab on Admin Laptop or Admin PC
Go to: https://192.168.99.2:8043
Accept the certificate warning
Log in with your Omada credentials

Verify:
  ☐  Dashboard loads at https://192.168.99.2:8043
  ☐  All devices adopted — none disconnected or pending
  ☐  Clients page shows all devices on correct VLANs
  ☐  SG2008P shows Online in Devices
  ☐  ER605 shows Online in Devices
  ☐  EAP shows Online in Devices
  ☐  OC200 shows IP 192.168.99.2 in Clients
```

---

### Final Verification — Before Closing the Window

```
Network:
  ☐  Every home device shows 192.168.10.x
  ☐  Internet works on all devices — wired and wireless
  ☐  No devices stuck on old flat network addresses

Pi-hole:
  ☐  Pi at 192.168.10.15 confirmed
  ☐  Pi-hole admin: http://192.168.10.15/admin loads
  ☐  Query log shows active DNS traffic from VLAN 10 devices
  ☐  VLAN 10 DNS shows 192.168.10.15 in Omada

Admin access:
  ☐  Dashboard at https://192.168.99.2:8043
  ☐  Admin PC reaches dashboard — 192.168.10.10 confirmed
  ☐  Admin Laptop reaches dashboard — 192.168.10.11 confirmed

Documentation:
  ☐  Change log entries completed in register
  ☐  Screenshot — Omada Clients — all devices on VLAN 10
  ☐  Screenshot — Port Settings — all profiles applied
  ☐  Screenshot — DHCP Reservations — all confirmed
  ☐  Post-window config backup taken
  ☐  Git commit — "Phase 1 complete — post-window baseline"
  ☐  Phase 1 checklist marked complete in NDD and register
```

---

### If Something Goes Wrong

**Lost dashboard access:**

```
Step 1 — try from Admin Laptop (Wi-Fi): https://192.168.99.2:8043
Step 2 — try from Admin PC (wired):     https://192.168.99.2:8043

Step 3 — if Step 7 Part B (Discovery Utility) was not completed:
  Re-run Discovery Utility → Batch Setting on ER605 → Controller IP: 192.168.99.2
  Wait 60 seconds → try dashboard again

Step 4 — last resort: patch cable directly to OC200 ETH2 (not ETH1)
  Set a temporary static IP on your laptop ethernet adapter:

  Windows:
    Settings → Network & Internet → ethernet → IP assignment → Edit → Manual
    IPv4 ON:
      IP address:            192.168.99.10
      Subnet prefix length:  24
      Gateway:               192.168.99.2
    Save → open browser → https://192.168.99.2:8043
    When done: set back to Automatic (DHCP)

  macOS:
    System Settings → Network → ethernet → Details → TCP/IP tab
    Configure IPv4: Manually
      IP Address:   192.168.99.10
      Subnet Mask:  255.255.255.0
      Router:       192.168.99.2
    OK → Apply → open browser → https://192.168.99.2:8043
    When done: set Configure IPv4 back to Using DHCP

  Linux:
    # Find your ethernet interface name
    ip link show

    # Set temporary static IP (replace eth0 with your interface)
    sudo ip addr add 192.168.99.10/24 dev eth0
    sudo ip route add default via 192.168.99.2
    Open browser → https://192.168.99.2:8043

    # When done — remove static config and reconnect
    sudo ip addr del 192.168.99.10/24 dev eth0
    sudo ip route del default via 192.168.99.2
    # Reconnect normally via NetworkManager or dhclient
```

**Devices showing disconnected after Step 7:**

```
Most likely cause: Discovery Utility Batch Setting not completed or failed.

→ Re-run Discovery Utility
→ Select ER605 → Batch Setting → Controller IP: 192.168.99.2
→ Apply → wait 60 seconds → refresh Omada Devices page
```

**Device stuck on wrong IP:**

```
Windows:
  ipconfig /release
  ipconfig /renew

macOS:
  System Settings → Network → [adapter] → Renew DHCP Lease
  Or: open Terminal → sudo ipconfig set en0 DHCP

Linux:
  sudo dhclient -r [interface]
  sudo dhclient [interface]

  With NetworkManager:
  nmcli device disconnect [interface]
  nmcli device connect [interface]

Last resort (any OS): power cycle the device
```

**Pi-hole not receiving queries:**

```
→ Confirm Pi is at 192.168.10.15 (hostname -I on Pi)
→ Check VLAN 10 DNS in Omada shows 192.168.10.15
→ On Pi: pihole restartdns
```

**Unexpected outage on any port change:**

```
→ Change the port back to its previous profile immediately
→ Diagnose from Admin Laptop before retrying
→ Do not proceed to the next step until current step is stable
```

---

## Changes From Previous Procedure — Summary

| Item | Old Procedure | Updated Procedure |
|------|--------------|-------------------|
| OC200 reservation Network field | Not specified | Must be MGMT VLAN 99 — not default LAN |
| Auto Refresh IP | Not mentioned | Must be enabled on OC200 before window |
| Discovery Utility | Not in procedure | Required after OC200 cutover — updates ER605 with new controller IP |
| Java requirement | Not mentioned | Java 17 (Win/Linux) — Zulu JDK 17 FX (Mac) |
| DHCP pool on MGMT | Required workaround | Not needed — firmware 6.2.0 supports reservations outside pool range |
| Reservation UI path | Settings → Services → DHCP Reservation | Clients → Manage Client → Config → Use Fixed IP Address |
| Verify reservations | Not specified | Network Config → DHCP Reservation |
| ER605 device account | Not mentioned | Must be written on paper before window — needed for Discovery Utility |
| IP renewal commands | Linux/Fedora only | Windows, macOS, and Linux all covered throughout |
| Static IP recovery | Linux nmcli only | Windows, macOS, and Linux all covered |

---

*Updated: 22/03/2026 — Reflects official Omada support documentation cross-reference*  
*Firmware baseline: OC200 6.2.0.122.24.6 Build 20260227*  
*OS coverage: Windows, macOS, Linux (Fedora/RHEL and Debian/Ubuntu)*
