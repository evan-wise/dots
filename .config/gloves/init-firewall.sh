#!/bin/bash
# Egress allowlist for the Claude Code sandbox. Adapted from the reference
# script in anthropics/claude-code/.devcontainer.
set -euo pipefail
IFS=$'\n\t'

# Preserve Docker's internal DNS NAT rules before flushing.
DOCKER_DNS_RULES=$(iptables-save -t nat | grep "127\.0\.0\.11" || true)

iptables -F; iptables -X
iptables -t nat -F; iptables -t nat -X
iptables -t mangle -F; iptables -t mangle -X
ipset destroy allowed-domains 2>/dev/null || true

if [ -n "$DOCKER_DNS_RULES" ]; then
  iptables -t nat -N DOCKER_OUTPUT 2>/dev/null || true
  iptables -t nat -N DOCKER_POSTROUTING 2>/dev/null || true
  echo "$DOCKER_DNS_RULES" | xargs -L 1 iptables -t nat
fi

# DNS, SSH (git), localhost.
iptables -A OUTPUT -p udp --dport 53 -j ACCEPT
iptables -A INPUT -p udp --sport 53 -j ACCEPT
iptables -A OUTPUT -p tcp --dport 22 -j ACCEPT
iptables -A INPUT -p tcp --sport 22 -m state --state ESTABLISHED -j ACCEPT
iptables -A INPUT -i lo -j ACCEPT
iptables -A OUTPUT -o lo -j ACCEPT

ipset create allowed-domains hash:net

echo "Fetching GitHub IP ranges..."
gh_ranges=$(curl -s https://api.github.com/meta)
if ! echo "$gh_ranges" | jq -e '.web and .api and .git' >/dev/null; then
  echo "ERROR: Failed to fetch valid GitHub IP ranges"
  exit 1
fi
while read -r cidr; do
  if [[ ! "$cidr" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}/[0-9]{1,2}$ ]]; then
    echo "ERROR: Invalid CIDR range from GitHub meta: $cidr"
    exit 1
  fi
  ipset add allowed-domains "$cidr"
done < <(echo "$gh_ranges" | jq -r '(.web + .api + .git)[]' | aggregate -q)

resolve_into_set() {
  local domain="$1" ips
  ips=$(dig +noall +answer A "$domain" | awk '$4 == "A" {print $5}')
  if [ -z "$ips" ]; then
    return 1
  fi
  while read -r ip; do ipset add -exist allowed-domains "$ip"; done < <(echo "$ips")
}

# Required for Claude Code to function; failure to resolve is fatal.
for domain in api.anthropic.com; do
  resolve_into_set "$domain" || { echo "ERROR: Failed to resolve $domain"; exit 1; }
done

# Everything else is best effort (a failed lookup only warns).
# Claude: login, native updater, telemetry. Node: npm, nodejs.org.
# Python: PyPI. Rust: crates.io, rustup. GitHub downloads (releases, raw).
for domain in \
  claude.ai platform.claude.com console.anthropic.com downloads.claude.ai \
  statsig.anthropic.com statsig.com sentry.io \
  registry.npmjs.org registry.yarnpkg.com nodejs.org \
  pypi.org files.pythonhosted.org \
  crates.io index.crates.io static.crates.io static.rust-lang.org sh.rustup.rs docs.rs \
  raw.githubusercontent.com objects.githubusercontent.com release-assets.githubusercontent.com \
  codeload.github.com mise.run mise.jdx.dev; do
  resolve_into_set "$domain" || echo "WARNING: could not resolve $domain, skipping"
done

HOST_IP=$(ip route | grep default | cut -d" " -f3)
if [ -z "$HOST_IP" ]; then
  echo "ERROR: Failed to detect host IP"
  exit 1
fi
HOST_NETWORK=$(echo "$HOST_IP" | sed "s/\.[0-9]*$/.0\/24/")
iptables -A INPUT -s "$HOST_NETWORK" -j ACCEPT
iptables -A OUTPUT -d "$HOST_NETWORK" -j ACCEPT

iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT DROP
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A OUTPUT -m set --match-set allowed-domains dst -j ACCEPT
iptables -A OUTPUT -j REJECT --reject-with icmp-admin-prohibited

# Block IPv6 egress entirely so it can't bypass the IPv4 allowlist.
if command -v ip6tables >/dev/null; then
  ip6tables -F 2>/dev/null || true
  ip6tables -A INPUT -i lo -j ACCEPT 2>/dev/null || true
  ip6tables -A OUTPUT -o lo -j ACCEPT 2>/dev/null || true
  ip6tables -P INPUT DROP 2>/dev/null || true
  ip6tables -P FORWARD DROP 2>/dev/null || true
  ip6tables -P OUTPUT DROP 2>/dev/null || true
fi

echo "Verifying firewall..."
if curl --connect-timeout 5 -s https://example.com >/dev/null 2>&1; then
  echo "ERROR: Firewall verification failed - reached https://example.com"
  exit 1
fi
if ! curl --connect-timeout 5 -s https://api.github.com/zen >/dev/null 2>&1; then
  echo "ERROR: Firewall verification failed - cannot reach api.github.com"
  exit 1
fi
echo "Firewall configured."
