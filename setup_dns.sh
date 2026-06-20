```bash
#!/bin/bash
# ==============================================================================
# Script Name:  setup_dns.sh
# Description:  Automated Installation & Architecture setup for Bind9 on Ubuntu 24.04
# Target Domain: astubind9.net
# ==============================================================================

set -e # Exit immediately if any command fails

echo "=== [1/6] Upgrading System and Installing Bind9 Utilities ==="
sudo apt update && sudo apt upgrade -y
sudo apt install -y bind9 bind9utils bind9-doc dnsutils

echo "=== [2/6] Writing Configuration Files ==="
# Configure named.conf.options
sudo tee /etc/bind/named.conf.options > /dev/null << 'EOF'
acl internal-network {
    10.240.34.0/24;
};

options {
    directory "/var/cache/bind";
    recursion yes;
    allow-query { localhost; internal-network; };
    allow-recursion { internal-network; };
    allow-transfer { localhost; };
    forwarders {
         8.8.8.8;
         8.8.4.4;
    };
    dnssec-validation no;
};
EOF

# Configure named.conf.local
sudo tee /etc/bind/named.conf.local > /dev/null << 'EOF'
zone "astubind9.net" IN {
    type master;
    file "/etc/bind/zones/db.forward.astubind9.net";
    allow-update { none; };
};

zone "1.168.192.in-addr.arpa" IN {
    type master;
    file "/etc/bind/zones/db.reverse.astubind9.net";
    allow-update { none; };
};
EOF

echo "=== [3/6] Provisioning Zone Database Directories ==="
sudo mkdir -p /etc/bind/zones

# Forward Zone DB
sudo tee /etc/bind/zones/db.forward.astubind9.net > /dev/null << 'EOF'
$TTL    604800
@       IN      SOA     pr.astubind9.net. root.pr.astubind9.net. (
                              2         ; Serial
                         604800         ; Refresh
                          86400         ; Retry
                        2419200         ; Expire
                         604800 )       ; Negative Cache TTL

@       IN  NS      pr.astubind9.net.
pr      IN  A       192.168.1.20
www     IN  A       192.168.1.50
mail    IN  A       192.168.1.60
@       IN  MX  10  mail.astubind9.net.
ftp     IN  CNAME   www.astubind9.net.
EOF

# Reverse Zone DB
sudo tee /etc/bind/zones/db.reverse.astubind9.net > /dev/null << 'EOF'
$TTL    604800
@       IN      SOA     pr.astubind9.net. root.pr.astubind9.net. (
                              2         ; Serial
                         604800         ; Refresh
                          86400         ; Retry
                        2419200         ; Expire
                         604800 )       ; Negative Cache TTL

@       IN  NS      pr.astubind9.net.
20      IN  PTR     pr.astubind9.net.
50      IN  PTR     www.astubind9.net.
60      IN  PTR     mail.astubind9.net.
EOF

echo "=== [4/6] Forcing IPv4 Daemon Mode ==="
sudo sed -i 's/OPTIONS=.*/OPTIONS="-u bind -4"/' /etc/default/named

echo "=== [5/6] Opening System Firewalls (UFW) ==="
sudo ufw allow bind9
sudo ufw reload

echo "=== [6/6] Validating Configurations & Restarting Service ==="
sudo named-checkconf -z /etc/bind/named.conf
sudo systemctl restart named
sudo systemctl enable named

echo "🚀 Bind9 Configuration Successfully Deployed under 'astubind9.net'!"