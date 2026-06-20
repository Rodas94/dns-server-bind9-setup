# Ubuntu 24.04 LTS DNS Server Setup (Bind9)

A comprehensive guide and automation suite for deploying a local Primary DNS Server using Bind9 on Ubuntu 24.04 Server.

## Table of Contents

- [Environment Architecture](#environment-architecture)
- [Configuration Blueprints](#configuration-blueprints)
  - [1. Global Daemon Options](#1-global-daemon-options-etcbindnamedconfoptions)
  - [2. Local Zone Declarations](#2-local-zone-declarations-etcbindnamedconflocal)
  - [3. Forward Mapping Zone File](#3-forward-mapping-zone-file-dbforwardastubind9net)
  - [4. Reverse Mapping Zone File](#4-reverse-mapping-zone-file-dbreverseastubind9net)
- [Operational Verification & Controls](#operational-verification--controls)
  - [Syntax Auditing](#syntax-auditing)
  - [Service Controls](#service-controls)
  - [Client-Side DNS Validation](#client-side-dns-validation)

## Environment Architecture

- **Domain Name:** `astubind9.net`
- **DNS Server IP:** `192.168.1.20`
- **Network ACL Scope:** `10.240.34.0/24`
- **Client Test Environment IP:** `10.0.2.15`

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
```

### 2. Local Zone Declarations (`/etc/bind/named.conf.local`)

```text
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
```

### 3. Forward Mapping Zone File (`db.forward.astubind9.net`)

```text
$TTL 604800
@ IN SOA pr.astubind9.net. root.pr.astubind9.net. (
2 ; Serial
604800 ; Refresh
86400 ; Retry
2419200 ; Expire
604800 ) ; Negative Cache TTL

; Name Server Records
@ IN NS pr.astubind9.net.

; Host A Records
pr IN A 192.168.1.20
www IN A 192.168.1.50
mail IN A 192.168.1.60

; Mail Exchanger Records
@ IN MX 10 mail.astubind9.net.

; Canonical Name Records
ftp IN CNAME www.astubind9.net.
```

### 4. Reverse Mapping Zone File (`db.reverse.astubind9.net`)

```text
$TTL 604800
@ IN SOA pr.astubind9.net. root.pr.astubind9.net. (
2 ; Serial
604800 ; Refresh
86400 ; Retry
2419200 ; Expire
604800 ) ; Negative Cache TTL

; Name Server Records
@ IN NS pr.astubind9.net.

; PTR Records (IP to Hostname)
20 IN PTR pr.astubind9.net.
50 IN PTR www.astubind9.net.
60 IN PTR mail.astubind9.net.
```

## Operational Verification & Controls

### Syntax Auditing

Validate configuration formatting prior to daemon restart:

```bash
sudo named-checkconf -z /etc/bind/named.conf
sudo named-checkzone astubind9.net /etc/bind/zones/db.forward.astubind9.net
sudo named-checkzone 1.168.192.in-addr.arpa /etc/bind/zones/db.reverse.astubind9.net
```

### Service Controls

```bash
sudo systemctl restart named
sudo systemctl status named
```

### Client-Side DNS Validation

```bash
dig pr.astubind9.net
dig -x 192.168.1.20
nslookup www.astubind9.net
```

## Additional Resources

- [Bind9 Documentation](https://bind.isc.org/doc/)
- [Ubuntu DNS Server Guide](https://ubuntu.com/server/docs/service-domain-name-service-dns)

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For issues or questions, please create an issue in the repository or contact the system administrator.
