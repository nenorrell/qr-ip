# qr-ip

📡 Instantly generate a QR code pointing to your local server — perfect for testing apps on mobile devices.

## 🧠 What It Does

`qr-ip` detects your **host machine's LAN IP** and starts a lightweight HTTP server that serves a QR code with the link to your app (e.g. `http://192.168.86.33:5173`). Scan the QR from your phone and access your app instantly — no setup required.

## 🚀 Quick Start

> ⚠️ Make sure Docker is installed and running on your machine.

### 1. Run it with curl (zero install)

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/nenorrell/qr-ip/master/run.sh)" <app-port> <exposed-port>
```

**Example:**

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/nenorrell/qr-ip/master/run.sh)" 5173 8080
```

* `5173` is your **app's internal port** (used in the QR code)
* `8080` is the optional **host port** (for browser access on your machine). Defaults to 80 if not specified.

### 2. Open on your phone

Scan the QR code with your phone camera or QR scanner — your app will open in the browser, using your machine's real LAN IP.

---

## 💠 Development

Clone the repo and build it manually if desired:

```bash
git clone https://github.com/nenorrell/qr-ip.git
cd qr-ip
docker build -t qr-ip .
make expose-qr-code  # runs the app with auto-detected IP
```

---

## ❓ Why This Exists

Accessing local dev servers on mobile is a pain. `qr-ip` solves that by:

* Detecting your host LAN IP
* Serving a QR code for instant mobile access
* Running entirely in a disposable Docker container

---

## 🔐 Note

This tool is meant for **local development only**. The generated QR code is not secure — it simply encodes an internal IP and port.
