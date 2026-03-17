# JXStudio Home Lab — Project Summary & Remaining Steps
**Site:** JXStudio  
**Date:** 16/03/2026  
**Status:** Phase 1 — Pre-window prep COMPLETE. Maintenance window today.  
**Companion Files:** `network-design-document.md` | `network-settings-register-POPULATED.md`

---

## ⚠️ Credentials — Write These Down On Paper Now

> These must be written on paper before the maintenance window begins.  
> Do not rely on digital access only — you may lose network access during the window.

| Item | Value |
|------|-------|
| Omada dashboard URL | https://192.168.99.2:8043 |
| Omada local username | `[your chosen username]` |
| Omada local password | `[your chosen password]` |
| Admin PC reserved IP | 192.168.10.10 |
| Admin Laptop reserved IP | 192.168.10.11 |
| Pi-hole reserved IP | 192.168.10.15 |
| Pi-hole admin page | http://192.168.10.15/admin |
| OC200 reserved IP | 192.168.99.2 |
| SG2008P management IP | 192.168.99.10 |
| Emergency direct access URL | https://192.168.99.2:8043 via patch cable to OC200 ETH2 |
| Emergency laptop static IP | 192.168.99.10/24 — GW 192.168.99.2 |

---

## Conversation Summary

This document summarises the full planning and build session for the JXStudio home lab network. It covers every major decision made, every issue encountered, and the current state of the project heading into the maintenance window.

---

### What Was Built — The Architecture

A four-VLAN segmented home lab network designed around an ISP rack (TP-Link Omada) and a server rack (Cisco). The design separates home devices, lab infrastructure, IoT devices, and network management into isolated networks with explicit inter-VLAN policy enforcement.

**VLAN Structure:**

| VLAN | Name | Subnet | Purpose |
|------|------|--------|---------|
| 10 | HOME | 192.168.10.0/24 | Home PCs, phones, TVs, consoles, Pi-hole |
| 20 | LAB | 192.168.20.0/24 | Servers, VMs, Proxmox infrastructure |
| 30 | IOT | 192.168.30.0/24 | Smart devices — fully isolated |
| 99 | MGMT | 192.168.99.0/24 | Network device management only |

**Hardware:**

| Device | Model | Role | Mgmt IP | Status |
|--------|-------|------|---------|--------|
| TP-Link ER605 v2.20 | ER605 | WAN Gateway | 192.168.10.1 | Active |
| TP-Link SG2008P v3.20 | SG2008BP | Managed PoE Switch | 192.168.99.10 | Active |
| TP-Link OC200 | OC200 | Omada Controller | 192.168.99.2 | Active |
| TP-Link EAP653 (US) v1.0 | EAP653 | Wireless AP | 192.168.99.x | Active |
| Raspberry Pi | `[model]` | Pi-hole DNS | 192.168.10.15 | Active — static IP removed ✅ |
| Cisco Catalyst 3750G | 3750G | L3 Core Switch | 192.168.99.3 | Planned — Phase 2 |
| Cisco Catalyst 2960G | 2960G | L2 Access / Lab | 192.168.99.4 | Planned — Phase 2/3 |
| Proxmox Server | `[model]` | Hypervisor | 192.168.20.10 | Planned — Phase 4 |
| Cisco 1921 x2 | 1921 | Lab Edge / VPN | .20.254 / .20.253 | Planned — Phase 7 |

---

### Key Decisions Made

**Switch Stack — Decision Pending**
Option A (3750G only, 2960G free for lab) vs Option B (both in production). Not yet confirmed — update the document header when decided.

**DNS Architecture — Two Phase**
- Phase 1: Pi-hole at 192.168.10.15 serves VLAN 10 only. No cross-VLAN ACL rules needed.
- Phase 2+: Pi moves to MGMT at 192.168.99.5. Serves all VLANs. DNS permit ACL rules added at that point.

**Controller IP — DHCP Reservation Approach**
After two failed attempts to manually change the OC200 IP (both resulting in auth failure and loss of access), the decision was made to use a DHCP reservation instead. The OC200 MAC ([MAC_REDACTED]) is reserved to 192.168.99.2. When Port 1 switches to MGMT profile during the maintenance window the controller picks up 192.168.99.2 automatically from the reservation. No manual IP change required.

**SG2008P Management VLAN — Maintenance Window Only**
In Omada 6.x the switch management VLAN is configured via VLAN Interface in the device config sidebar — not a simple IP field. Changing it before the port profiles are applied physically would cause the controller to lose the switch immediately. This step is performed during the maintenance window after trunk and MGMT port assignments are confirmed working.

**ACL Enforcement — Two Layer**
- Omada Gateway ACL handles broad VLAN-to-VLAN policy (Phase 1 active)
- Cisco 3750G IOS ACLs handle host-level fine-grained rules (Phase 2+)

**Two-Tier Access Architecture**
- Tier 1 (Services): Home devices → Reverse Proxy (192.168.20.50) only
- Tier 2 (Management): Specific admin IPs → Proxmox :8006 / SSH direct only
- Proxmox is never a reverse proxy target

**Port Profiles in Omada 6.x — Behaviour Only**
In Omada 6.1.0.19 VLAN settings were removed from port profiles entirely. Port profiles are now behaviour-only templates (PoE, flow control, spanning tree). VLAN assignment is done directly on ports in Port Settings during the maintenance window.

---

### Issues Encountered and Resolved

**OC200 Controller Access Loss — Twice**
Root cause: Manually changing the controller IP while actively managing a live network caused the application service to enter a half-started auth state. Web UI loaded but authentication failed consistently.
Resolution: Factory reset with config backup restore. IP change handled via DHCP reservation during maintenance window — no manual change required.

**SG2008P Management IP Path Changed in 6.x**
The switch management VLAN is no longer under Config > Advanced. It is now under VLAN Interface in the device config sidebar. Changing this before the physical port configuration is in place loses the switch from the controller.

**Direct Access Recovery Procedure — For Reference**
If the controller becomes unreachable on the network:
```bash
# Connect patch cable: Laptop ETH → OC200 ETH2 (not ETH1 — Port 1 carries PoE power)
# Set static IP on Fedora laptop
sudo nmcli con add type ethernet \
  ifname [iface] \
  con-name direct-oc200 \
  ip4 192.168.99.10/24 \
  gw4 192.168.99.2
sudo nmcli con up direct-oc200
ping 192.168.99.2
# Access https://192.168.99.2:8043 or http://192.168.99.2:8088
# After recovery:
sudo nmcli con delete direct-oc200
```

**ER605 Login Lockout**
Caused by attempting login on the ER605 page while believing it was the OC200. 2 hour lockout after repeated failed attempts. Resolution: wait for timer to clear.

---

### Static IP and MAC Register

| Device | IP | VLAN | MAC |
|--------|-----|------|-----|
| ER605 — WAN Gateway | 192.168.10.1 | 10 | [MAC_REDACTED] |
| OC200 — Omada Controller | 192.168.99.2 | 99 | [MAC_REDACTED] |
| TL-SG2008P | 192.168.99.10 | 99 | [MAC_REDACTED] |
| EAP653 | 192.168.99.x | 99 | [MAC_REDACTED] |
| Admin PC | 192.168.10.10 | 10 | [MAC_REDACTED] |
| Admin Laptop | 192.168.10.11 | 10 | [MAC_REDACTED] |
| Partner PC | 192.168.10.12 | 10 | `[MAC]` |
| Raspberry Pi — Pi-hole | 192.168.10.15 | 10 | [MAC_REDACTED] |
| Philips Hue Bridge | 192.168.30.5 | 30 | [MAC_REDACTED] |
| Proxmox Host | 192.168.20.10 | 20 | `[MAC — Phase 4]` |
| Nginx Proxy Manager | 192.168.20.50 | 20 | N/A — VM |
| Tailscale LXC | 192.168.20.51 | 20 | N/A — LXC |
| 3750G SVI MGMT | 192.168.99.3 | 99 | N/A |
| 2960G MGMT | 192.168.99.4 | 99 | N/A |
| Pi-hole (Phase 2+) | 192.168.99.5 | 99 | Same Pi MAC |

---

### ACL Rules — Current State

**Active — Phase 1 (Gateway ACL — LAN→LAN)**

| # | Name | Source → Destination | Policy | Status |
|---|------|----------------------|--------|--------|
| 1 | Home-to-MGMT | HOME → MGMT | Permit | ✅ Enabled |
| 2 | Block-Home-to-Lab | HOME → LAB | Deny | ✅ Enabled |
| 3 | Block-Home-to-IoT | HOME → IOT | Deny | ✅ Enabled |
| 4 | Block-IoT-to-Home | IOT → HOME | Deny | ✅ Enabled |
| 5 | Block-IoT-to-Lab | IOT → LAB | Deny | ✅ Enabled |
| 6 | Block-IoT-to-MGMT | IOT → MGMT | Deny | ✅ Enabled |
| 7 | MGMT-Full-Access | MGMT → HOME, LAB, IOT | Permit | ✅ Enabled |

**Pending — Add when each phase goes live**

| Rule | Waiting On |
|------|------------|
| Admin-PC/Laptop → Proxmox TCP 8006 | Phase 4 |
| Admin-PC/Laptop → Lab SSH TCP 22 | Phase 4 |
| Home → Proxy HTTP/HTTPS | Phase 5 |
| Lab → Home | Phase 4 |
| IoT/Lab/MGMT → Pi-hole UDP+TCP 53 | Phase 2+ |

---

## Pre-Window Prep — Status

| Task | Status |
|------|--------|
| VLANs 10, 20, 30, 99 created on ER605 | ✅ Complete |
| DHCP pools configured per VLAN | ✅ Complete |
| DHCP reservations set — all devices | ✅ Complete |
| 7 Gateway ACL rules created and enabled | ✅ Complete |
| IP Groups created — all 5 | ✅ Complete |
| OC200 reset and config restored | ✅ Complete |
| Port profiles created — HOME, MGMT, TRUNK-ALL, LAN-Uplink | ✅ Complete |
| Raspberry Pi static IP removed — Pi back up on DHCP | ✅ Complete |
| Fresh config backup saved to Git repo | ✅ Complete |
| SG2008P management VLAN | ⏩ Moved to maintenance window — Step 6 |
| Credentials written on paper | ☐ Do this before starting the window |

> **Pre-window prep is complete. Write credentials on paper then begin the window.**

---

## Maintenance Window — Revised Order of Operations

> Admin PC handles Steps 3 and 4 — it still has flat network dashboard access.  
> Admin Laptop takes over as primary dashboard from Step 5 onward.  
> One step at a time. Verify before moving on.

---

### Current Port Map — SG2008P

```
Port 1  — OC200 Omada Controller     → Step 5 — last
Port 2  — EAP653 WAP                 → ✅ Complete
Port 3  — Raspberry Pi (MAC confirms)→ Step 6 — after Step 5
Port 4  — DESKTOP-CE1DDUF            → identify then Step 6
Port 5  — Philips Hue Bridge         → ✅ Complete — HOME
Port 6  — Vizio TV                   → ✅ Complete
Port 7  — Nothing connected          → leave
Port 8  — ER605 LAN uplink           → leave
```

---

### How to Change a Port — Field by Field

```
Where: Devices → SG2008P → Ports → Port Settings
Click a port row to open the Edit panel on the right

For any HOME device port:
  Native Network:        HOME (10)
  Network Tags Setting:  Custom
  Tagged Networks:       clear all tags
  Untagged Network:      HOME (10)
  Profile:               HOME
  → Apply

For Port 1 — OC200 only — do last:
  Native Network:        MGMT (99)
  Network Tags Setting:  Custom
  Tagged Networks:       clear all tags
  Untagged Network:      MGMT (99)
  Profile:               MGMT
  → Apply
```

---

### Step 1 — Remaining Home Devices ✅ In Progress

```
✅  Port 6 — Vizio TV          → HOME — verified
✅  Port 5 — Philips Hue Bridge → HOME — verified
☐   Port 4 — DESKTOP-CE1DDUF   → identify first

To identify Port 4 device:
  Check hostname on each machine — Windows: open terminal → hostname
  Match to DESKTOP-CE1DDUF
  Change to HOME profile once confirmed

Verify after each port change:
  ☐  Device shows 192.168.10.x in Omada → Clients
  ☐  Internet works on the device
  ☐  No other devices lost connectivity
```

---

### Step 2 — EAP Port ✅ Complete

```
✅  Port 2 — EAP653 → HOME profile
    Admin Laptop confirmed on 192.168.10.11 via Wi-Fi

    Note: Admin Laptop is on VLAN 10 but dashboard is still
    on flat network. Admin PC handles Steps 3 and 4.
    Admin Laptop takes over as primary from Step 5 onward.
```

---

### Step 3 — Update Pi-hole DNS in Omada

```
Do from Admin PC — still has flat network dashboard access

Where: Settings → Wired Networks → LAN → HOME (VLAN 10)

Action:
  Change DNS Primary from 1.1.1.1 to 192.168.10.15
  Save

Note: Pi not yet on VLAN 10 — takes effect after Step 6.

Verify:
  ☐  DNS saved as 192.168.10.15 in VLAN 10 config
```

---

### Step 4 — SG2008P Management VLAN → 99

```
Do from Admin PC — still has flat network dashboard access

Where: Devices → SG2008P → Config tab
  → click VLAN Interface in the left sidebar

Action:
  Management VLAN field — currently shows Default (1)
  Change to MGMT (99)
  Apply

  ★  This is safe now because home device ports are already
     on VLAN 10. The physical layer matches the management
     VLAN change.

Verify:
  ☐  Switch still shows Connected in Omada Devices
  ☐  Switch config still accessible from Admin PC
  ☐  Do not proceed to Step 5 until confirmed connected
```

---

### Step 5 — OC200 Port → MGMT Profile

```
Do from Admin PC — last action before it loses flat network access

Pre-flight before touching Port 1:
  ☐  Admin Laptop on 192.168.10.11 with internet — confirmed
  ☐  SG2008P management VLAN confirmed on 99 — Step 4 done
  ☐  Dashboard URL ready: https://192.168.99.2:8043
  ☐  Credentials confirmed

Action:
  Devices → SG2008P → Ports → Port Settings
  Click Port 1 (OC200)
  Set fields as per How to Change a Port — MGMT values
  Apply
  Dashboard goes offline immediately — expected
  OC200 picks up 192.168.99.2 from DHCP reservation

Reconnect from Admin Laptop:
  Open browser → https://192.168.99.2:8043
  Accept certificate warning — click Advanced → Proceed
  Log in

  ★  Admin Laptop is now primary dashboard access
     ACL Rule 1 permits HOME (192.168.10.11) → MGMT (192.168.99.2)

Verify from Admin Laptop:
  ☐  Dashboard loads at https://192.168.99.2:8043
  ☐  All devices adopted — none disconnected or pending
  ☐  SG2008P shows Connected in Devices
  ☐  ER605 shows Connected in Devices
  ☐  EAP shows Connected in Devices
```

---

### Step 6 — Admin PC + Raspberry Pi Port → HOME Profile

```
Do from Admin Laptop — now confirmed in dashboard at new address

Note: Confirm whether Admin PC and Pi share Port 3 via the
unmanaged switch or are on separate ports before proceeding.
If shared — both move simultaneously when that port changes.

Action:
  Change Port 3 (and Port 4 if Admin PC is there) to HOME profile
  Using HOME field values from How to Change a Port above

What happens:
  Admin PC  → DHCP → 192.168.10.10 (reservation)
  Pi        → DHCP → 192.168.10.15 (reservation)

Verify Admin PC:
  ☐  Shows 192.168.10.10 — run ipconfig in terminal
  ☐  Internet works from Admin PC
  ☐  Admin PC can reach https://192.168.99.2:8043
     (ACL Rule 1 permits HOME → MGMT)

Verify Pi via KVM:
  ☐  Shows 192.168.10.15 — run hostname -I
  ☐  Pi-hole admin loads: http://192.168.10.15/admin
  ☐  Pi-hole query log shows DNS activity populating

If Admin PC gets wrong IP:
  → ipconfig /release then ipconfig /renew
  → If still wrong — check reservation MAC matches exactly

If Pi gets wrong IP:
  → sudo dhclient -r then sudo dhclient
  → Check reservation MAC matches exactly
```

---

### Final Verification — Before Closing the Window

```
Network:
  ☐  Every home device shows 192.168.10.x
  ☐  Internet works on all devices — wired and wireless
  ☐  No devices stuck on old flat network addresses

Pi-hole:
  ☐  Pi at 192.168.10.15 confirmed via KVM
  ☐  Pi-hole admin: http://192.168.10.15/admin loads
  ☐  Query log shows active DNS traffic
  ☐  VLAN 10 DNS shows 192.168.10.15 in Omada

Admin access:
  ☐  Dashboard at https://192.168.99.2:8043
  ☐  Admin PC reaches dashboard — 192.168.10.10 confirmed
  ☐  Admin Laptop reaches dashboard — 192.168.10.11 confirmed

Documentation:
  ☐  Change log entries completed in register
  ☐  Screenshot — Omada Clients — all devices on VLAN 10
  ☐  Screenshot — Port Settings — all profiles applied
  ☐  Post-window config backup taken
  ☐  Git commit — "Phase 1 complete — post-window baseline"
  ☐  Phase 1 checklist marked complete in NDD and register
```

---

### If Something Goes Wrong

```
Lost dashboard access:
  → Try https://192.168.99.2:8043 from Admin Laptop (Wi-Fi)
  → Try https://192.168.99.2:8043 from Admin PC
  → If neither — patch cable to OC200 ETH2 (see recovery above)

Device stuck on wrong IP:
  → Windows: ipconfig /release then ipconfig /renew
  → Linux/Pi: sudo dhclient -r then sudo dhclient
  → Last resort: power cycle the device

Pi-hole not receiving queries:
  → Confirm Pi is at 192.168.10.15 via KVM
  → Check VLAN 10 DNS in Omada shows 192.168.10.15
  → pihole restartdns

Unexpected outage on any port change:
  → Change the port back to previous profile immediately
  → Diagnose from Admin Laptop before retrying
  → Do not proceed until current step is resolved
```

---

## Future Phases — Remaining Work

### Phase 2 — Catalyst 3750G
- [ ] Confirm Option A vs Option B — update all docs
- [ ] Verify IOS version and feature set — `show version` / `show license`
- [ ] Configure VLANs, SVIs, default route, inter-rack trunk
- [ ] Configure IOS ACLs for host-level rules
- [ ] Connect inter-rack trunk — SG2008P Port 7 to 3750G Gi0/1
- [ ] Test inter-VLAN routing
- [ ] Back up running config to Git

### Phase 3 — Catalyst 2960G (Option B Only)
- [ ] Configure as access layer switch
- [ ] Cascade trunk to 3750G
- [ ] Test and document

### Phase 4 — Proxmox
- [ ] Install Proxmox on server
- [ ] Configure VLAN-aware bridge from day one — set bridge-vlan-aware yes
- [ ] Assign static IP 192.168.20.10
- [ ] Enable pending ACL rules — Proxmox :8006 and SSH
- [ ] Enable pending ACL rule — Lab-to-Home

### Phase 5 — Nginx Proxy Manager
- [ ] Create LXC — 192.168.20.50 VLAN 20
- [ ] Install and configure Nginx Proxy Manager
- [ ] Enable pending ACL rules — Home-to-Proxy HTTP/HTTPS
- [ ] Add services to proxy register

### Phase 6 — Tailscale
- [ ] Create LXC — 192.168.20.51 VLAN 20
- [ ] Configure as subnet router
- [ ] Advertise 192.168.10.0/24, 192.168.20.0/24, 192.168.30.0/24
- [ ] Approve routes in Tailscale admin console

### Phase 2+ — Pi-hole Network-Wide
- [ ] DHCP reservation on MGMT — Pi MAC → 192.168.99.5
- [ ] Change Pi port to MGMT profile
- [ ] Configure Pi-hole to listen on all interfaces
- [ ] Add DNS ACL permit rules — IoT, Lab, MGMT → 192.168.99.5 port 53
- [ ] Update all VLAN DNS entries to 192.168.99.5

### Phase 7 — Cisco 1921 Routers (Optional)
- [ ] Lab edge and VPN configuration
- [ ] Document in NDD

---

## Documentation Status

| Document | Status | Notes |
|----------|--------|-------|
| network-design-document.md | Current | Update after window |
| network-settings-register-POPULATED.md | Current | Update after window |
| network-settings-register-TEMPLATE.md | Complete | No changes needed |
| network-design-document-TEMPLATE.md | Complete | No changes needed |
| network_setup_quick_guide.md | Needs updates | See list below |
| CLAUDE.md | Current | Update after window |
| project-summary-and-remaining-steps.md | This file | Update after window |

### Quick Guide Updates Still Needed
- [ ] OC200 IP in body text: 192.168.99.1 → 192.168.99.2 (two places)
- [ ] Add dashboard URL: https://192.168.99.2:8043
- [ ] Clean up OC200 and Hue Bridge reservation table rows
- [ ] Add note: Hue Bridge stays on HOME until Phase 2
- [ ] Mark HOME DNS 1.1.1.1 as temporary
- [ ] Verify Pi MAC discrepancy: quick guide .B5:34 vs register .B5:43 — check device

---

*Last updated: 16/03/2026 — Pre-window prep complete. Maintenance window ready to begin.*
