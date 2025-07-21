#!/usr/bin/env bash
# --------------------------------------------------------
# find-host-ip.sh
#
# Prints the first "real" LAN IPv4 address and exits:
#   0 → success, IP printed to stdout
#   1 → could not detect a suitable IP
#
#  • Prefers the interface used for the default route
#  • Skips Docker-Desktop / VM subnets (192.168.65.0/24)
#  • Falls back to common Wi-Fi / Ethernet ports (en0-en3)
#  • Final fallback: first RFC1918 IPv4 it can find
# --------------------------------------------------------

set -euo pipefail

is_docker_subnet() {
  [[ $1 =~ ^192\.168\.65\. ]]
}

# ---------- macOS detection ----------
get_ip_macos() {
  # 1. default-route interface
  local iface ip
  iface="$(route get default 2>/dev/null | awk '/interface:/{print $2}' || true)"
  [[ -n $iface ]] && ip=$(ipconfig getifaddr "$iface" 2>/dev/null || true)

  # 2. try common Wi-Fi / Ethernet names
  if [[ -z $ip || $(is_docker_subnet "$ip" && echo yes) == yes ]]; then
    for cand in en0 en1 en2 en3; do
      ip=$(ipconfig getifaddr "$cand" 2>/dev/null || true)
      [[ -n $ip && $(is_docker_subnet "$ip" && echo no) == no ]] && break
    done
  fi

  # 3. scan ifconfig for first private IPv4
  if [[ -z $ip || $(is_docker_subnet "$ip" && echo yes) == yes ]]; then
    ip=$(ifconfig | awk '/inet /{print $2}' \
       | grep -E '^(10\.|172\.(1[6-9]|2[0-9]|3[0-1])\.|192\.168\.)' \
       | grep -v '^192\.168\.65\.' | head -n1 || true)
  fi
  echo "$ip"
}

# ---------- Linux detection ----------
get_ip_linux() {
  local iface ip
  iface="$(ip route show default 2>/dev/null | awk '{print $5}' | head -n1)"
  [[ -n $iface ]] && ip="$(ip -4 -o addr show dev "$iface" | awk '{print $4}' | cut -d/ -f1)"

  # fallback: first private IPv4 not on docker0
  if [[ -z $ip || $(is_docker_subnet "$ip" && echo yes) == yes ]]; then
    ip=$(ip -4 -o addr show \
        | awk '{print $4}' | cut -d/ -f1 \
        | grep -E '^(10\.|172\.(1[6-9]|2[0-9]|3[0-1])\.|192\.168\.)' \
        | grep -v '^192\.168\.65\.' | head -n1 || true)
  fi
  echo "$ip"
}

# ---------- main ----------
ip=""
case "$(uname -s)" in
  Darwin) ip=$(get_ip_macos) ;;
  Linux)  ip=$(get_ip_linux) ;;
  *)      echo "Unsupported OS" >&2; exit 1 ;;
esac

if [[ -z $ip ]]; then
  echo "Could not detect LAN IP" >&2
  exit 1
fi

echo "$ip"
