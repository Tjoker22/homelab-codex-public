# 🏠 [Your Lab Name] Home Lab
**Status:** 🛠️ Rebuilding (Started: Feb 2026)

This repository is the source of truth for my Proxmox environment. It tracks hardware allocation, networking, and service configurations.

---

## 🖥️ Hypervisor Hardware
* **Host CPU:** [e.g., Intel i7-10700K]
* **Host RAM:** [e.g., 64GB DDR4]
* **Storage Pools:**
    * `local-lvm`: [Size] (OS & ISOs)
    * `data-ssd`: [Size] (VM/LXC Disks)

---

## 🌐 Network Map
* **Gateway:** [e.g., 192.168.1.1]
* **DNS:** [e.g., 192.168.1.5 (Pi-hole)]
* **Domain:** `jxstudios.dev`

| ID | Name | Type | IP Address | Description |
| :--- | :--- | :--- | :--- | :--- |
| 100 | [Name] | VM | [IP] | [Purpose] |
| 101 | [Name] | LXC | [IP] | [Purpose] |

---

## 📁 Infrastructure Documentation
* [**Virtual Machines (VMs)**](./vms/)
* [**Containers (LXCs)**](./containers/)
* [**Networking & Firewalls**](./network/)

---

## ⚡ Quick Maintenance
* **Backup Schedule:** [e.g., Nightly at 02:00 to PBS]
* **Update Command:** `sudo apt update && sudo apt upgrade -y`