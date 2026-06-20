# Ubuntu 24.04 LTS DNS Server Setup (Bind9)

A comprehensive guide and automation suite for deploying a local Primary DNS Server using Bind9 on Ubuntu 24.04 Server.

## Environment Architecture
* **Domain Name:** `astubind9.net`
* **DNS Server IP:** `192.168.1.20`
* **Network ACL Scope:** `10.240.34.0/24`
* **Client Test Environment IP:** `10.0.2.15`

---

## Configuration Blueprints

### 1. Global Daemon Options (`/etc/bind/named.conf.options`)
```text
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