# **🛠️ The "Universal" Proxmox Instance Template**

### **1. Identity & Context**

* **Hostname:** [e.g., nginx-proxy-01]
* **Proxmox ID:** [e.g., 100]
* **Purpose:** [One sentence: Why does this exist?]
* **Tags:** [e.g., Production, Web, Internal, Testing]
* **OS/Image:** [e.g., Ubuntu 22.04 / Debian-12-Turnkey]

### **2. Hardware Profile (Pick One)**

#### **[ ] IF VIRTUAL MACHINE (VM)**

* **CPU:** [x] Cores | Type: [host / kvm64]
* **RAM:** [x] GB | Ballooning: [Yes/No]
* **Boot:** [SeaBIOS / UEFI (OVMF)]
* **OS Drive:** [Size] on [local-lvm / data-ssd]
* **Extra Disks:** [Size] on [storage-pool]

#### **[ ] IF CONTAINER (LXC)**

* **Privileged:** [No (Default) / Yes]
* **Resources:** [x] Cores | [x] MB RAM
* **Mount Points:** [e.g., /mnt/data -> /pool/shared]
* **Features:** [e.g., Nesting=1 (for Docker), FUSE, NFS]

### **3. Networking & Security**

* **IP Address:** [Static / DHCP Reservation]
* **MAC Address:** [XX:XX:XX...] (Keep this for DHCP static leases)
* **VLAN/Bridge:** [vmbr0] | Tag: [None]
* **Firewall (UFW):** [Active / Inactive]
  * *Allowed Ports:* [e.g., 80, 443, 22]
* **Fail2Ban:** [Enabled / Disabled]

### **4. Service & Application Stack**

* **Primary App:** [e.g., Nginx / Pi-hole]
* **Dependency:** [e.g., Needs 'db-vm-01' to boot first]
* **Install Method:** [e.g., Docker-Compose / Script / Manual Apt]
* **Key Paths:**
  * *Configs:* [e.g., /etc/nginx/]
  * *Logs:* [e.g., /var/log/nginx/]
* **Web UI/Entry:** [e.g., http://192.168.1.10:8080]

### **5. Operations & Disaster Recovery**

* **Backup Job:** [Daily / Weekly] to [Proxmox Backup Server / NAS]
* **Update Command:** [e.g., sudo apt update && sudo apt upgrade -y]
* **"Panic" Note:** [e.g., If this fails, the entire jxstudios.dev domain goes offline!]
