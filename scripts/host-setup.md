# 🖥️ Proxmox Host Setup & Configuration
**Installation Date:** March 2026
**Hardware:** [e.g., Dell Optiplex / Custom Build]

---

## 1. Storage Configuration
*Record how the physical disks are partitioned. Proxmox uses ZFS or LVM.*

* **OS Drive (Local):** [Size] NVMe/SSD
    * *Usage:* Proxmox OS, ISO Images, and Container Templates.
* **VM Data Drive (Dedicated):** [Size] SSD/HDD
    * *Proxmox ID:* `data-ssd` (or whatever you named it in the GUI)
    * *Content:* All VM/LXC disks.
* **ISO/Backup Path:** `/var/lib/vz` (Default)

---

## 2. Networking (Physical & Virtual)
*This is the "Don't Lock Yourself Out" section.*

* **Management IP:** `192.168.1.XX` (Static)
* **Linux Bridge (`vmbr0`):** Linked to Physical Port `[e.g., enp3s0]`
* **VLANs:** [None / List IDs if using tagging]

---

## 3. Post-Install "Quality of Life"
*Commands or scripts run immediately after installation.*

* **Proxmox VE Post-Install Script:** [e.g., Proxmox Helper Scripts used?]
* **Repositories:** [No-Subscription Repo enabled?]
* **Dark Mode:** [Enabled?]

---

## 4. Installed Packages (Host Level)
*Packages installed directly on the Proxmox shell (keep this minimal!).*
* `git` (For syncing this documentation)
* `vim/nano`
* `htop`

---

## 5. UPS / Power Management
* **Model:** [e.g., APC Back-UPS]
* **Software:** `NUT` or `APCUSB`
* **Shutdown Logic:** [Shut down VMs at 20% battery?]