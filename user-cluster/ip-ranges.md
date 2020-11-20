
# user cluster ip ranges

- clusterDNS: `10.240.16.10`
- clusterCIDR: `172.25.0.0/16`
- servicesCIDR: `10.240.16.0/20`
- k8c api k8s server: https://10.2.0.82:30303
- nodelocal dns: `169.254.20.10/32`
- vpn server: `remote 10.2.0.82 32359`
- vpn client `/bin/sh -c "/sbin/iptables -t nat -I POSTROUTING -s 10.20.0.0/24 -j MASQUERADE"`