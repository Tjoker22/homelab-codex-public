| NETWORK DESIGN DOCUMENT & CONFIGURATION RECORD ──────────────────────────────────────────── Base Template — Complete all highlighted fields |
| :---: |

| ℹ HOW TO USE THIS TEMPLATE Fields highlighted in yellow are placeholders — replace them with your actual values. All tables in this document should be kept current whenever a change is made to the network. Use the Change Log (last section) to record every modification. See companion spreadsheet (Network\_Settings\_Register.xlsx) for the living settings tables. |
| :---- |

| Document Control |  |
| :---- | :---- |
| **Document Title** | e.g. Home Lab Network Design Document |
| **Owner / Author** | Your name |
| **Location** | e.g. Git repo URL, folder path, Notion link |
| **Current Version** | e.g. 1.0 |
| **Date Created** | DD/MM/YYYY |
| **Date Last Updated** | DD/MM/YYYY |
| **Switch Stack Option** | ☐  Option A — Single Switch (3750G only)          ☐  Option B — Dual Switch (3750G \+ 2960G) |
| **Notes** | Any free-text notes about this document or the environment |

# **Section 1 — Environment Overview**

| ℹ WHEN TO UPDATE Complete this section once at initial setup. Update only when physical equipment changes — new device added, device replaced, rack layout change. |
| :---- |

## **1.1 — Site Information**

| Site Name / Label | e.g. Home Lab — Main Residence |
| :---- | :---- |
| **ISP / WAN Type** | e.g. Fibre 1Gbps — Provider name |
| **WAN IP Type** | ☐  Dynamic (DHCP from ISP)          ☐  Static — IP: \_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_ |
| **Physical Racks** | e.g. 2 racks — ISP Rack (12U) and Server Rack (18U) |
| **Inter-rack Cable** | e.g. Cat6A 5m — TL-SG2008P Port 7 to 3750G Gi0/1 |

## **1.2 — Hardware Inventory**

| \# | Device | Model / Version | Rack | Role | Management IP |
| :---- | :---- | :---- | :---- | :---- | :---- |
| 1 | WAN Router | TP-Link ER605 v2 | ISP Rack | WAN Gateway | 192.168.10.1 |
| 2 | PoE Switch | TL-SG2008P | ISP Rack | Managed Switch | 192.168.99.10 |
| 3 | Controller | Omada Hardware Controller | ISP Rack | Omada Controller | 192.168.99.1 |
| 4 | L3 Core Switch | Catalyst 3750G — XX port — IP/IP Services | Server Rack | L3 Core | 192.168.99.2 |
| 5 | L2 Access Switch | Catalyst 2960G (Option B) / Unplugged (Option A) | Server Rack / Lab | Access / Lab | 192.168.99.3 / N/A |
| 6 | Hypervisor | Proxmox VE — version X.X | Server Rack | Hypervisor | 192.168.20.10 |
| 7 | Router \#1 | Cisco 1921 — IOS version | Server Rack / Lab | Lab Edge / Lab | 192.168.20.254 / N/A |
| 8 | Router \#2 | Cisco 1921 — IOS version | Server Rack / Lab | VPN / Lab | 192.168.20.253 / N/A |
| 9 | WAP | TP-Link EAP — model | Location | Wireless AP | 192.168.99.XX |
| 10 | Add device | Model | Rack/Location | Role | IP |

# **Section 2 — VLAN Design**

| ℹ WHEN TO UPDATE This section defines the intended VLAN design. Update when a new VLAN is added or an existing VLAN's parameters change. Each change must also be recorded in the Change Log. |
| :---- |

## **2.1 — VLAN Register**

| ID | Name | Subnet | Gateway IP | DHCP Range | DNS Servers | DHCP |
| :---- | :---- | :---- | :---- | :---- | :---- | :---- |
| **10** | HOME | 192.168.10.0/24 | 192.168.10.1 | .100 – .200 | 1.1.1.1 / X.X.X.X | ON |
| **20** | LAB | 192.168.20.0/24 | 192.168.20.1 | .100 – .200 | 1.1.1.1 / X.X.X.X | ON |
| **30** | IOT | 192.168.30.0/24 | 192.168.30.1 | .100 – .200 | 9.9.9.9 | ON |
| **99** | MGMT | 192.168.99.0/24 | 192.168.99.1 | N/A | 192.168.99.1 | OFF |
| ID | Name | Subnet | Gateway | Range | DNS | ON/OFF |

## **2.2 — DHCP Range Rationale**

Document the reasoning behind each VLAN's DHCP range here. Update if ranges are changed.

| VLAN | Static Reserved (.1 – .X) | DHCP Pool | Rationale |
| :---- | :---- | :---- | :---- |
| HOME 10 | .1 – .29 | .30 – .254 | Mostly dynamic devices. Wide pool. Few static IPs needed. |
| LAB 20 | .1 – .99 | .100 – .200 | Many static servers and VMs. Reserve .1–.99 for infrastructure. |
| IOT 30 | .1 – .19 | .20 – .254 | Almost all dynamic. Wide pool. Very few static IoT devices. |
| MGMT 99 | All addresses | DHCP disabled | All MGMT devices have static IPs. No dynamic assignment. |

## **2.3 — Inter-VLAN Traffic Policy**

Document the intended traffic policy between VLANs. This drives both the ER605 firewall rules and the 3750G ACLs.

| Source | Destination | Action | Description / Rationale |
| :---- | :---- | :---- | :---- |
| e.g. HOME 10 — admin IPs | LAB 20 — Proxmox :8006 | PERMIT | Specific admin devices only — per DHCP reservation |
| HOME 10 — any | Proxy VM :80/:443 | PERMIT | All home devices reach services via reverse proxy |
| HOME 10 | LAB 20 — direct | BLOCK | Home devices blocked from direct lab access |
| HOME 10 | IOT 30 | BLOCK | No home-to-IoT lateral movement |
| IOT 30 | Any internal | BLOCK | IoT fully isolated — internet only |
| LAB 20 | HOME 10 | PERMIT | Lab admin access to home resources |
| MGMT 99 | Any | PERMIT | Management VLAN — full access |
| Add rule |  |  |  |

# **Section 3 — Static IP Address Register**

| ℹ WHEN TO UPDATE Add every device that has a static IP or DHCP reservation. This is the authoritative IP reference. Update immediately when a device is added, removed, or its IP changes. Cross-reference with the DHCP Reservations tab in the companion spreadsheet. |
| :---- |

| Device / Hostname | IP Address | VLAN | MAC Address | Type | Notes |
| :---- | :---- | :---- | :---- | :---- | :---- |
| ER605 (WAN Gateway) | 192.168.10.1 | 10 | [MAC_REDACTED] | Static | WAN GW — do not change |
| Omada Controller | 192.168.99.1 | 99 | [MAC_REDACTED] | Static | Fixed — controller address |
| TL-SG2008P | 192.168.99.10 | 99 | [MAC_REDACTED] | Static | Omada managed switch |
| 3750G — SVI 99 | 192.168.99.2 | 99 | N/A | Static | Core switch MGMT |
| 3750G — SVI 20 | 192.168.20.1 | 20 | N/A | Static | Lab VLAN gateway |
| 3750G — SVI 30 | 192.168.30.1 | 30 | N/A | Static | IoT VLAN gateway |
| 3750G — SVI 10 | 192.168.10.2 | 10 | N/A | Static | Home SVI |
| 2960G (Option B) | 192.168.99.3 | 99 | [MAC_REDACTED] | Static | Access switch MGMT (Option B only) |
| Proxmox Host | 192.168.20.10 | 20 | [MAC_REDACTED] | Static | Hypervisor — web UI :8006 |
| Nginx Proxy Manager | 192.168.20.50 | 20 | N/A (VM) | Static | Reverse proxy — ACL rule target |
| Tailscale LXC | 192.168.20.51 | 20 | N/A (LXC) | Static | Subnet router — ACL permit |
| Admin PC | 192.168.10.10 | 10 | [MAC_REDACTED] | Reservation | Daily driver — in ACL permit rules |
| Admin Laptop | 192.168.10.11 | 10 | [MAC_REDACTED] | Reservation | Secondary admin — in ACL permit rules |
| Add device | IP | VLAN | MAC | Type | Notes |
| Add device | IP | VLAN | MAC | Type | Notes |

# **Section 4 — Omada GUI Configuration Record**

| ℹ WHEN TO UPDATE Record every setting configured in the Omada GUI here. This section is the fallback reference if the controller needs to be rebuilt. Update immediately after any change is applied in the UI. Attach screenshots to the companion folder. |
| :---- |

## **4.1 — ER605 LAN / VLAN Definitions**

For each entry: Settings \> Wired Networks \> LAN. One row per VLAN.

| VLAN ID | Name | IP / Mask | DHCP Range | DNS | Lease | Purpose Tag |
| :---- | :---- | :---- | :---- | :---- | :---- | :---- |
| 10 | HOME | 192.168.10.1/24 | .100–.200 | 1.1.1.1 | 1d | Home |
| 20 | LAB | 192.168.20.1/24 | .100–.200 | 1.1.1.1 | 1d | Lab/Servers |
| 30 | IOT | 192.168.30.1/24 | .100–.200 | 9.9.9.9 | 1d | IoT Only |
| 99 | MGMT | 192.168.99.1/24 | DISABLED | 192.168.99.1 | N/A | Admin Only |

## **4.2 — DHCP Reservations**

Settings \> Wired Networks \> LAN \> select VLAN \> DHCP Reservation. One row per reserved device.

| Device Name | MAC Address | Reserved IP | VLAN | Date Set |
| :---- | :---- | :---- | :---- | :---- |
| Admin PC — daily driver | [MAC_REDACTED] | 192.168.10.10 | HOME — VLAN 10 | DD/MM/YYYY |
| Admin Laptop | [MAC_REDACTED] | 192.168.10.11 | HOME — VLAN 10 | DD/MM/YYYY |
| Add device | MAC | Reserved IP | VLAN | Date |
| Add device | MAC | Reserved IP | VLAN | Date |

## **4.3 — TL-SG2008P Switch Port Profiles**

Devices \> TL-SG2008P \> Config \> Port Config. Document each port profile and its assignment.

| Port | Profile Applied | Untagged VLAN | Tagged VLANs | Native VLAN | Connected Device |
| :---- | :---- | :---- | :---- | :---- | :---- |
| 1 | MGMT | 99 | None | 99 | Omada Controller |
| 2 | HOME | 10 | None | 10 |  |
| 3 | HOME | 10 | None | 10 |  |
| 4 | HOME | 10 | None | 10 |  |
| 5 | HOME | 10 | None | 10 |  |
| 6 | HOME | 10 | None | 10 | WAP — TP-Link EAP |
| 7 | TRUNK-ALL | None | 10,20,30,99 | 99 | 3750G Gi0/1 — inter-rack trunk |
| 8 | LAN Uplink | 10 | None | 10 | ER605 LAN port |

## **4.4 — Switch Port Profiles Defined in Omada**

Settings \> Profiles \> Switch Profiles. One row per profile created.

| Profile Name | Untagged VLAN | Tagged VLANs | Native VLAN | Used On Ports |
| :---- | :---- | :---- | :---- | :---- |
| HOME | 10 | None | 10 | 2,3,4,5,6 |
| MGMT | 99 | None | 99 | 1 |
| TRUNK-ALL | None | 10,20,30,99 | 99 | 7 |
| Add profile |  |  |  |  |

## **4.5 — WAP SSID Configuration**

Wireless \> Wi-Fi. One row per SSID. Note VLAN tag and which WAP it broadcasts from.

| SSID Name | VLAN Tag | Band | Security | WAP Device | Notes |
| :---- | :---- | :---- | :---- | :---- | :---- |
| e.g. HomeNet | 10 | 2.4 \+ 5GHz | WPA2/WPA3 | EAP-XXX | Main home SSID |
| e.g. LabWiFi | 20 | 5GHz | WPA2 | EAP-XXX | Admin devices only |
| e.g. IoT-Net | 30 | 2.4GHz | WPA2 | EAP-XXX | Smart devices — isolated |
| Add SSID |  |  |  |  |  |

## **4.6 — ER605 Firewall Rules**

Settings \> Transmission \> Firewall. Rules are evaluated top-down. Document every rule in order. Populate the Description field in the GUI to match this table.

| ⚠ IMPORTANT Rule order is critical. A misplaced rule can silently allow or block traffic in unexpected ways. Any time a rule is added, removed, or reordered — update this table and record the change in the Change Log. |
| :---- |

| \# | Source | Destination | Port / Proto | Action | Description (match GUI field exactly) | En |
| :---- | :---- | :---- | :---- | :---- | :---- | :---- |
| 1 | 192.168.10.10 | 192.168.20.10 | TCP :8006 | ACCEPT | Admin PC → Proxmox Web UI | Y |
| 2 | 192.168.10.10 | 192.168.20.0/24 | TCP :22 | ACCEPT | Admin PC → Lab SSH | Y |
| 3 | 192.168.10.0/24 | 192.168.20.50 | TCP :80,:443 | ACCEPT | Home → Reverse Proxy (services) | Y |
| 4 | 192.168.10.0/24 | 192.168.20.0/24 | Any | DROP | Block Home → Lab (direct) | Y |
| 5 | 192.168.10.0/24 | 192.168.30.0/24 | Any | DROP | Block Home → IoT | Y |
| 6 | 192.168.30.0/24 | 192.168.10.0/24 | Any | DROP | Block IoT → Home | Y |
| 7 | 192.168.30.0/24 | 192.168.20.0/24 | Any | DROP | Block IoT → Lab | Y |
| 8 | 192.168.99.0/24 | Any | Any | ACCEPT | MGMT VLAN — full access | Y |
| 9 | Any | WAN | Any | ACCEPT | Internet access — all VLANs | Y |
| \# | Source | Destination | Port/Proto | Action | Description | Y/N |

# **Section 5 — Cisco Device Configuration Snapshot**

| ℹ WHEN TO UPDATE After completing initial configuration on each Cisco device, paste the relevant sections of the running config below. Update after every significant config change. Use 'show running-config' to retrieve. Store full configs in the companion Git repository. |
| :---- |

## **5.1 — 3750G Key Configuration Snapshot**

Record hostname, IOS version, and key config sections. Full config stored in Git.

| 3750G — Device Info |  |
| :---- | :---- |
| **Hostname** | SW-CORE-3750G |
| **IOS Version** | e.g. 12.2(55)SE12 — run: show version |
| **Feature Set** | IP Base / IP Services — run: show license |
| **Stack Option** | ☐  Option A — acting as L3 core \+ access     ☐  Option B — acting as L3 core only |
| **Last Config Backup** | DD/MM/YYYY — filename / Git commit |
| **VLAN Database** | VLANs 10 HOME, 20 LAB, 30 IOT, 99 MGMT — VLAN 1 shutdown |
| **Active SVIs** | Vlan10 .10.2, Vlan20 .20.1, Vlan30 .30.1, Vlan99 .99.2 |
| **Default Route** | ip route 0.0.0.0 0.0.0.0 192.168.10.1 |
| **ACLs Applied** | VLAN10-IN on Vlan10 in, VLAN30-IN on Vlan30 in, VLAN20-IN on Vlan20 in |
| **SSH / Auth** | SSH v2, RSA 2048, local auth, VTY transport input ssh |
| **Notes** | Any other notable config items |

## **5.2 — 2960G Key Configuration Snapshot (Option B Only)**

| 2960G — Device Info (Option B Only) |  |
| :---- | :---- |
| **Hostname** | SW-ACCESS-2960G |
| **IOS Version** | e.g. 12.2(55)SE12 |
| **Management IP** | 192.168.99.3 (Vlan99) |
| **Default Gateway** | 192.168.99.2 (3750G SVI) |
| **Uplink Port** | Gi0/1 — trunk to 3750G Gi0/2 |
| **Last Config Backup** | DD/MM/YYYY — filename / Git commit |

# **Section 6 — Proxmox & Services Record**

| ℹ WHEN TO UPDATE Update this section when VMs or LXC containers are created, removed, or have their network config changed. One row per VM/LXC. |
| :---- |

## **6.1 — VM / LXC Register**

| ID | Name / Hostname | Type | IP Address | VLAN Tag | OS | Purpose / Services |
| :---- | :---- | :---- | :---- | :---- | :---- | :---- |
| 100 | nginx-proxy | LXC | 192.168.20.50 | 20 | Debian 12 | Nginx Proxy Manager — reverse proxy |
| 101 | tailscale | LXC | 192.168.20.51 | 20 | Debian 12 | Tailscale subnet router |
| 102 |  | VM/LXC |  |  |  |  |
| 103 |  | VM/LXC |  |  |  |  |

## **6.2 — Reverse Proxy Service Register**

One row per service configured in Nginx Proxy Manager. Update when a service is added, removed, or its target changes.

| Domain / Hostname | Forward Host (IP) | Port | SSL | Notes |
| :---- | :---- | :---- | :---- | :---- |
| homepage.lab.home | 192.168.20.55 | 3000 | No | Home dashboard |
| grafana.lab.home | 192.168.20.56 | 3000 | Yes | Metrics dashboard |
| Add service |  |  |  |  |
| **DO NOT ADD** | Proxmox :8006 | N/A | N/A | NEVER proxy Proxmox — admin ACL only |

# **Section 7 — Change Log**

| ℹ WHEN TO UPDATE Record EVERY change made to the network after initial setup — no matter how small. This is the most important section for long-term maintainability. If something breaks and you need to trace the cause, this log is what you'll reach for first. |
| :---- |

| ⚠ IMPORTANT Before making any change: note the current state in the 'Previous Value' column. After the change: record the new value, test result, and any rollback steps needed. A change without a log entry is a change that cannot be safely undone. |
| :---- |

| Date | Device / Section | What Changed | Previous Value | New Value | Reason / Notes |
| :---- | :---- | :---- | :---- | :---- | :---- |
| DD/MM/YY | e.g. ER605 / Firewall | Added firewall rule \#3 — home to proxy permit | Rule did not exist | ACCEPT home:any → 20.50 :80/:443 | Enable service access from home devices |
| DD/MM/YY |  |  |  |  |  |
| DD/MM/YY |  |  |  |  |  |
| DD/MM/YY |  |  |  |  |  |
| DD/MM/YY |  |  |  |  |  |
| DD/MM/YY |  |  |  |  |  |
| DD/MM/YY |  |  |  |  |  |
| DD/MM/YY |  |  |  |  |  |
| DD/MM/YY |  |  |  |  |  |
| DD/MM/YY |  |  |  |  |  |
| DD/MM/YY |  |  |  |  |  |
| DD/MM/YY |  |  |  |  |  |
| DD/MM/YY |  |  |  |  |  |
| DD/MM/YY |  |  |  |  |  |
| DD/MM/YY |  |  |  |  |  |
| DD/MM/YY |  |  |  |  |  |
| DD/MM/YY |  |  |  |  |  |
| DD/MM/YY |  |  |  |  |  |
| DD/MM/YY |  |  |  |  |  |

# **Section 8 — Screenshot & Backup Reference Log**

| ℹ HOW TO USE Use this section to log where screenshots and config backups are stored. Screenshots do not go in this document — store them in the companion folder and reference them here. |
| :---- |

## **8.1 — Screenshot Folder Structure**

Recommended folder structure for companion screenshot archive:

|   /Network-Docs/     /Screenshots/       /Omada/         VLAN-Definitions-YYYYMMDD.png         Port-Profiles-YYYYMMDD.png         Firewall-Rules-YYYYMMDD.png         DHCP-Reservations-YYYYMMDD.png         SSID-Config-YYYYMMDD.png       /Proxmox/         VM-List-YYYYMMDD.png         Network-Bridge-Config-YYYYMMDD.png       /NginxProxyManager/         Proxy-Hosts-YYYYMMDD.png     /Configs/       3750G-running-config-YYYYMMDD.txt       2960G-running-config-YYYYMMDD.txt       1921A-running-config-YYYYMMDD.txt       1921B-running-config-YYYYMMDD.txt |
| :---- |

## **8.2 — Config Backup Log**

| Date | Device | Filename / Commit | Notes |
| :---- | :---- | :---- | :---- |
| DD/MM/YY | 3750G | 3750G-initial-YYYYMMDD.txt | Initial config after Phase 2 complete |
| DD/MM/YY | 2960G | 2960G-initial-YYYYMMDD.txt | Initial config after Phase 3 complete |
| DD/MM/YY |  |  |  |
| DD/MM/YY |  |  |  |
| DD/MM/YY |  |  |  |
