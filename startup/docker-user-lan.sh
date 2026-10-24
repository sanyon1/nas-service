#!/bin/bash
# Docker publishes ports past ufw. Limit published container ports to the LAN:
# connections arriving on the uplink from outside LAN_CIDR are dropped, except 443/tcp (Caddy).
# Idempotent: safe to run repeatedly (e.g. after docker restarts).
set -euo pipefail

WAN_IF=enp8s0
LAN_CIDR=192.168.50.0/24
PUBLIC_TCP_PORT=443

ipt=/usr/sbin/iptables

add() {
    $ipt -C DOCKER-USER "$@" 2>/dev/null || $ipt -I DOCKER-USER "$@"
}

# -I prepends, so add the DROP first and the 443 exception last (it ends up above the DROP).
add -i "$WAN_IF" ! -s "$LAN_CIDR" -m conntrack --ctstate DNAT -j DROP
add -i "$WAN_IF" ! -s "$LAN_CIDR" -p tcp -m conntrack --ctstate DNAT --ctorigdstport "$PUBLIC_TCP_PORT" -j RETURN
