## **4.1 — VLAN & DHCP Configuration on ER605**

1. Navigate to Settings \> Wired Networks \> LAN \> Create New LAN

2. Create all four networks using the table below, clicking Apply after each:

| Field | HOME | LAB | IOT | MGMT |
| :---- | :---- | :---- | :---- | :---- |
| **VLAN ID** | 10 | 20 | 30 | 99 |
| **Gateway/Mask** | 192.168.10.1/24 | 192.168.20.1/24 | 192.168.30.1/24 | 192.168.99.1/24 |
| **DHCP** | Enable | Enable | Enable | Disable |
| **DHCP Range** | .10.100–.10.200 | .20.100–.20.200 | .30.20–.30.254 | N/A |
| **DNS** | 1.1.1.1 / 8.8.8.8 | 1.1.1.1 / 1.0.0.1 | 9.9.9.9 | 192.168.99.1 |

## **4.2 — DHCP Reservations for Admin Devices**

| ★ NEW — EXPANDED CONTENT Set DHCP reservations BEFORE writing any ACL rules. The ACL rules reference specific IPs — if those IPs change, access breaks. Reservations bind a device's MAC address to a fixed IP so it always gets the same address via DHCP, without manual static IP configuration on the device itself. |
| :---- |

3. Navigate to Settings \> Wired Networks \> LAN \> select HOME (VLAN 10\) \> DHCP Reservation

4. For each admin device, click Add and enter its MAC address and desired fixed IP:

| Device | Reserved IP | MAC ADdress | Notes |
| :--- | :--- | --- | :--- |
| Main PC (daily driver) | 192.168.10.10 | [MAC_REDACTED] | Primary admin machine — used in all ACL permit rules |
| Admin Laptop (if applicable) | 192.168.10.11 | [MAC_REDACTED] | Secondary admin device — add ACL permit line for this IP too |
| Additional admin devices | 192.168.10.12+ |  | Any device you regularly use for server management |
| Raspberry Pi | 192.168.10.15 | [MAC_REDACTED] | home vlan pi-hole - later network device |
| OC200 — Omada Controller | 192.168.99.2 | [MAC_REDACTED] | MGMT — VLAN 99 | `[Date]` | ACL Rule 1 destination | DHCP briefly enabled on MGMT to assign — disable after |
| Philips Hue Bridge | 192.168.30.5 | [MAC_REDACTED] | IOT — VLAN 30 | `[Date — when moved]` | None needed | Set when moving to IOT VLAN |

Find a device's MAC address via: Windows — ipconfig /all | Android/iOS — Settings \> WiFi \> tap network \> Advanced | Linux — ip link show

**DNS Providers — and a Correction**

Worth flagging: **1.1.1.1 is Cloudflare, not Google.** Google's DNS is 8.8.8.8 and 8.8.4.4. The guide currently pairs them together which is actually mixing two different providers, which isn't wrong but is worth understanding. Here's a full breakdown of reputable options:

| Provider | Primary | Secondary | Notes |
|---|---|---|---|
| **Cloudflare** | 1.1.1.1 | 1.0.0.1 | Fastest average response time globally. Strong privacy policy — logs purged within 24 hours. No filtering. |
| **Google** | 8.8.8.8 | 8.8.4.4 | Very reliable, widely used. Google does collect query data for analytics. |
| **Quad9** | 9.9.9.9 | 149.112.112.112 | Blocks known malicious domains at the DNS level. Good for IoT VLAN specifically — adds a layer of protection for devices that can't run their own security software. |
| **OpenDNS (Cisco)** | 208.67.222.222 | 208.67.220.220 | Configurable filtering, family shield variant available. Owned by Cisco — good fit given your Cisco lab gear. Has a free tier. |
| **NextDNS** | Custom per account | Custom | Cloud-based Pi-hole alternative. Highly configurable filtering, logging, analytics. Free tier with query limits. |
| **Pi-hole (self-hosted)** | Your Pi-hole IP | Fallback of choice | Runs as a VM or LXC on Proxmox. Blocks ads and trackers network-wide, full query logging, points upstream to any provider above. |

**Recommended approach for your specific VLANs:**

- **HOME (10):** Cloudflare (1.1.1.1) or Pi-hole if you set one up — ad blocking benefits everyone on the home network.
- **LAB (20):** Cloudflare (1.1.1.1) or your own internal DNS if you run one. Lab machines don't need filtering — speed and reliability matter more.
- **IOT (30):** Quad9 (9.9.9.9) is a strong choice here specifically. IoT devices are high-value targets for DNS-based attacks and can't protect themselves — having malicious domain blocking at the resolver level is a meaningful extra layer.
- **MGMT (99):** Point at your internal DNS or the ER605 itself (192.168.99.1) — management traffic should resolve internally first.

Pi-hole running as an LXC on Proxmox is worth considering as a Phase 5 addition alongside the reverse proxy. It would become the DNS server for all VLANs and forward upstream to whichever providers you choose, giving you a single pane of glass for all DNS queries across your entire network.

---

**What LAN→LAN Actually Supports in This Version**

LAN→LAN only works at the VLAN level — HOME, LAB, IOT, MGMT as whole networks. It cannot target individual host IPs. This means rules 9–15 in your list (all the block rules and VLAN-to-VLAN permits) work perfectly with LAN→LAN. Rules 1–8 that reference specific IPs (192.168.10.10, 192.168.10.11, etc.) need a different approach.

---

**The IP Group Approach for Host-Specific Rules**

When Direction is left unset, the Type dropdown expands to show IP Group and IP-Port Group. This is the correct path for host-specific rules. The process is:

**First — pre-create your IP Groups** before building those rules. In Omada go to Settings > Profiles > IP Groups and create one group per host:

| Group Name | IP / Subnet |
|---|---|
| Admin-PC | 192.168.10.10/32 |
| Admin-Laptop | 192.168.10.11/32 |
| OC-Controller | 192.168.99.2/32 |
| Proxmox | 192.168.20.10/32 |
| Proxy-VM | 192.168.20.50/32 |

The /32 mask means exactly one host — that single IP address only.

Then when creating rules 1–8, select IP Group as the source type and pick the appropriate group from the list. Same for destinations.

---

**However — Here's the Practical Reality for Right Now**

Rules 3–8 are all disabled anyway until Proxmox, the proxy, and the lab are built. You don't need to figure out the IP Group approach for those today.

Rules 1 and 2 (admin PC and laptop to the Omada Controller) are the only host-specific rules you actually need active right now. And honestly there is a simpler alternative for those two specifically — since the only thing on MGMT right now is the Omada Controller itself, you can write rule 1 and 2 as:

```
Direction:    LAN->LAN
Policy:       Permit
Protocol:     TCP
Source:       Network — HOME
Destination:  Network — MGMT
```

This permits the entire HOME VLAN to reach MGMT on TCP. It's broader than ideal — any home device could technically reach the controller login page — but your controller login credentials protect it, and right now HOME only has trusted personal devices on it anyway. You can tighten this to specific IPs later using IP Groups once you've confirmed everything is working.

---

**Recommended Build Order Given This UI**

**Do these now using LAN→LAN + Network — these are your critical rules:**

| # | Source | Destination | Policy | Notes |
|---|---|---|---|---|
| 1 | HOME | MGMT | Permit | Broad for now — tighten later |
| 2 | Block-Home-to-Lab | HOME → LAB | Deny | |
| 3 | Block-Home-to-IoT | HOME → IOT | Deny | |
| 4 | Block-IoT-to-Home | IOT → HOME | Deny | |
| 5 | Block-IoT-to-Lab | IOT → LAB | Deny | |
| 6 | Block-IoT-to-MGMT | IOT → MGMT | Deny | |
| 7 | MGMT-Full-Access | MGMT → All | Permit | Check HOME, LAB, IOT all selected |

**Create IP Groups now but build these rules later when you need them:**
Rules for Proxmox, Proxy, SSH — create the IP Groups as a prep step, build the actual rules when those servers exist.

---

**The Bigger Picture**

This is actually fine architecture. Omada's Gateway ACL handles the VLAN-to-VLAN policy coarsely, and when the Cisco 3750G comes online in Phase 2, its ACLs handle the fine-grained host-level rules (specific IP to specific port) natively in IOS — which is much more capable than Omada's UI for that level of detail. The two layers complement each other rather than duplicating each other.

---
## **The 7 Rules — Field by Field**

---

**Rule 1 — Home to MGMT (Admin access to Omada Controller)**

```
Description:  Home-to-MGMT
Status:       Enable
Direction:    LAN->LAN
Policy:       Permit
Protocol:     TCP

Source
  Type:       Network
  Network:    HOME ← checkbox

Destination
  Type:       Network
  Network:    MGMT ← checkbox
```

---

**Rule 2 — Block Home to Lab**

```
Description:  Block-Home-to-Lab
Status:       Enable
Direction:    LAN->LAN
Policy:       Deny
Protocol:     All

Source
  Type:       Network
  Network:    HOME ← checkbox

Destination
  Type:       Network
  Network:    LAB ← checkbox
```

---

**Rule 3 — Block Home to IoT**

```
Description:  Block-Home-to-IoT
Status:       Enable
Direction:    LAN->LAN
Policy:       Deny
Protocol:     All

Source
  Type:       Network
  Network:    HOME ← checkbox

Destination
  Type:       Network
  Network:    IOT ← checkbox
```

---

**Rule 4 — Block IoT to Home**

```
Description:  Block-IoT-to-Home
Status:       Enable
Direction:    LAN->LAN
Policy:       Deny
Protocol:     All

Source
  Type:       Network
  Network:    IOT ← checkbox

Destination
  Type:       Network
  Network:    HOME ← checkbox
```

---

**Rule 5 — Block IoT to Lab**

```
Description:  Block-IoT-to-Lab
Status:       Enable
Direction:    LAN->LAN
Policy:       Deny
Protocol:     All

Source
  Type:       Network
  Network:    IOT ← checkbox

Destination
  Type:       Network
  Network:    LAB ← checkbox
```

---

**Rule 6 — Block IoT to MGMT**

```
Description:  Block-IoT-to-MGMT
Status:       Enable
Direction:    LAN->LAN
Policy:       Deny
Protocol:     All

Source
  Type:       Network
  Network:    IOT ← checkbox

Destination
  Type:       Network
  Network:    MGMT ← checkbox
```

---

**Rule 7 — MGMT Full Access**

```
Description:  MGMT-Full-Access
Status:       Enable
Direction:    LAN->LAN
Policy:       Permit
Protocol:     All

Source
  Type:       Network
  Network:    MGMT ← checkbox

Destination
  Type:       Network
  Network:    HOME ← checkbox
              LAB  ← checkbox
              IOT  ← checkbox
```

---
---

## **MGMT IP Refresh — When and How**

There are two devices that need their management IPs set — the Omada Controller and the TL-SG2008P. Both must be done **before** you change any port profiles. Here's the exact timing and steps:

---

**When exactly:**

```
✔  VLANs and DHCP pools created
✔  DHCP reservations set
✔  ACL rules written  ← you're here now
→  Set OC static IP   ← do this next
→  Set switch MGMT IP ← then this
→  Then start port profile changes
```

Do not touch any port profiles until both IPs are set. If Port 1 switches to MGMT before the OC knows its new IP, you lose the dashboard with no way back in except physical access to the controller hardware.

---

**Step 1 — Set the Omada Controller static IP**

This is done inside the controller's own system settings, not in the network dashboard. In Omada 5.x:

```
Settings > Controller > Controller Settings
  or
Settings > Maintenance > (look for Network / IP settings)
```

Set it to:
```
IP Address:   192.168.99.1
Subnet Mask:  255.255.255.0
Gateway:      192.168.99.1
DNS:          1.1.1.1
```

The gateway being itself is correct — the ER605 handles routing for MGMT but the OC is the gateway IP for that subnet.

Save and let it apply. The controller may briefly restart or lose connection — this is normal. Wait for it to come back before proceeding.

---

**Step 2 — Set the TL-SG2008P management IP**

Done inside Omada dashboard:

```
Devices → click TL-SG2008P → Config tab → Advanced
  or
Devices → click TL-SG2008P → look for Management VLAN / IP settings
```

Set it to:
```
IP Address:   192.168.99.10
Subnet Mask:  255.255.255.0
Gateway:      192.168.99.1
Management VLAN: 99
```

Save and apply.

---

## **4.3 — TL-SG2008P Port Configuration in Omada**

5. Navigate to Devices \> click TL-SG2008P \> Config \> Port Config

6. Create a trunk profile: Profiles \> Switch Profiles \> Create \> name it TRUNK-ALL \> tag VLANs 10,20,30,99 \> set native VLAN to 99

7. Apply port profiles as follows:

* Port 1: MGMT profile (untagged VLAN 99\)

* Ports 2–6: HOME profile (untagged VLAN 10\) — downstream expander switch connects to any of these

* Port 7: TRUNK-ALL profile — this is the inter-rack trunk to the 3750G

* Port 8: Default LAN / ER605 uplink profile

---

### Phase 1 — Detailed Checklist

- [ X ] VLANs 10, 20, 30, 99 created on ER605
- [ X ] DHCP pools configured per VLAN
- [ X ] DHCP reservations set — Admin PC (.10.10), Admin Laptop (.10.11)
- [ X ] 7 Gateway ACL rules created and enabled
- [ X ] IP Groups pre-created in Omada Profiles (Admin-PC, Admin-Laptop, Proxmox, Proxy-VM, Pi-hole)
- [ ] OC200 static IP set to 192.168.99.2
- [ ] TL-SG2008P management IP set to 192.168.99.10
- [ ] Port profiles created — HOME, MGMT, TRUNK-ALL, LAN-Uplink
- [ ] Media devices (TV, PS5) moved to VLAN 10 — tested, internet confirmed
- [ ] Raspberry Pi static IP removed, DHCP reservation set to 192.168.10.15
- [ ] Pi-hole confirmed working on VLAN 10, DHCP DNS updated to 192.168.10.15
- [ ] Remaining home devices moved to VLAN 10
- [ ] Admin Laptop moved to VLAN 10 — confirmed 192.168.10.11
- [ ] OC200 Port 1 and Admin PC Port 3 switched last — back to back
- [ ] Dashboard confirmed accessible at https://192.168.99.2:8043
- [ ] All devices shown as adopted in Omada
- [ ] Phase 1 change log entries completed in register
