#!/usr/bin/env bash
set -euo pipefail

# ------------ Parse args ------------
TARGET_PORT="${1:-80}"   # QR port
VIEW_PORT="${2:-8080}"     # browser port

IMAGE="ghcr.io/nenorrell/qp-ip:latest"

# ------------ Detect LAN IP (macOS & Linux) ------------
detect_ip() {
  case "$(uname -s)" in
    Darwin)
      # default-route interface
      iface=$(route get default 2>/dev/null | awk '/interface:/{print $2}' || true)
      [[ -n $iface ]] && ip=$(ipconfig getifaddr "$iface" 2>/dev/null || true)
      # fallbacks
      for cand in en0 en1 en2; do
        [[ -z $ip || $ip =~ ^192\.168\.65\. ]] && ip=$(ipconfig getifaddr "$cand" 2>/dev/null || true)
      done
      ;;
    Linux)
      iface=$(ip route show default 2>/dev/null | awk '{print $5}' | head -n1)
      [[ -n $iface ]] && ip=$(ip -4 -o addr show dev "$iface" | awk '{print $4}' | cut -d/ -f1)
      # fallback: first private IPv4 not 192.168.65.*
      [[ -z $ip || $ip =~ ^192\.168\.65\. ]] && \
        ip=$(ip -4 -o addr show | awk '{print $4}' | cut -d/ -f1 \
            | grep -E '^(10\.|172\.(1[6-9]|2[0-9]|3[0-1])\.|192\.168\.)' \
            | grep -v '^192\.168\.65\.' | head -n1)
      ;;
  esac
  echo "$ip"
}

HOST_IP="${HOST_IP:-$(detect_ip)}"
[[ -z $HOST_IP ]] && { echo "Could not detect LAN IP. Set HOST_IP env." >&2; exit 1; }

echo "🚀  Embedding http://$HOST_IP:$TARGET_PORT"
echo "🌐  Opening page on http://localhost:$VIEW_PORT"

docker run --rm -it --init \
  -e HOST_IP="$HOST_IP" \
  -p "$VIEW_PORT":80 \
  "$IMAGE" "$TARGET_PORT"
