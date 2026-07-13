# ⚡ roc-containers

**Container Manager + AI Agent CLI for Termux** — Run Docker images di Termux tanpa root, dengan [udocker](https://github.com/indigo-dc/udocker).

> **Created by: ivansslo (2026)** · **License: MIT**

---

## 🚀 Quick Install

```bash
pkg install git -y
git clone --depth 1 https://github.com/ivansslo/roc-containers ~/.roc-containers
bash ~/.roc-containers/setup.sh
```

One-liner:
```bash
curl -s https://raw.githubusercontent.com/ivansslo/roc-containers/main/setup.sh | bash
```

---

## 📋 Command List

Setelah install, semua command langsung tersedia:

### 🤖 AI & Agent
| Command | Fungsi |
|---|---|
| `roc-agent` | AI Agent CLI utama — chat, ask, code, agent |
| `roc-hermes` | Hermes Agent (container, root, venv) |
| `roc-crewai` | CrewAI multi-agent (Groq/Gemini) |
| `roc-adk` | ADK Invoice Processing (Google) |
| `roc-antigravity` | Google AI IDE (port 5905) |

### 🐧 OS Containers
| Command | Fungsi |
|---|---|
| `roc-ubuntu` | Ubuntu 22.04 (port 2223) |
| `roc-debian` | Debian 12 (port 2224) |
| `roc-kali` | Kali Linux Minimal (port 2222) |
| `roc-nethunter` | Kali NetHunter Full (port 2222) |

### 🌐 Network & Services
| Command | Fungsi |
|---|---|
| `roc-tailscale` | Tailscale VPN (container node) |
| `roc-jupyter` | JupyterLab (port 8888) |
| `roc-httpd` | HTTP Server (port 3000) |
| `roc-redis` | Redis Server |
| `roc-ros` | ROS Robot OS |
| `roc-calibre` | Calibre-Web e-books |

### ⚙️ System
| Command | Fungsi |
|---|---|
| `roc-menu` | Menu interaktif utama |
| `roc-status` | Container manager (ID/Status) |
| `roc-gcp` | Google Cloud tools |
| `roc-sysinfo` | System info (RAM/CPU) |
| `roc-update` | Update roc-containers |
| `roc-uninstall` | Uninstall / clean |
| `roc-udocker` | Reinstall udocker |

---

## 🔑 Setup API Keys

```bash
# Interactive
roc-agent setup

# Atau manual
cat > ~/.hermes_keys << 'EOF'
GROQ_KEY=gsk_xxxxxx
GEMINI_API_KEY=AIzaSxxxxxx
OR_KEY=sk-or-xxxxxx
TOKEN=hk-xxxxxx
EOF
chmod 600 ~/.hermes_keys
```

---

## 🖥️ Menu Interaktif

```bash
roc-menu
```

```
 ╔══════════════════════════════════════════════════════╗
 ║ roc-containers · Container Manager                   ║
 ╚══════════════════════════════════════════════════════╝

 ── 🐧 Operating Systems ──
 [01] Ubuntu 22.04 LTS        → port 2223
 [02] Debian 12 Bookworm      → port 2224

 ── 🛡️ Security & Pentest ──
 [03] Kali NetHunter (Full)   → port 2222
 [04] Kali Linux (Minimal)    → port 2222

 ── ☁️ Apps & Dev ──
 [05] JupyterLab / Dev        → port 8888

 ── ⌨️ CLI Command ──
 [06] CLI Command (Agent/CrewAI/Tailscale/HTTP)

 ── 🟦 Google Project ──
 [07] Google Project (GCP tools)

 ── 🔧 System Utilities ──
 [08] Container Manager (ID/Status)
 [09] System Info (RAM/CPU)
 [10] Uninstall / Clean
 [11] Update roc-containers
 [12] Reinstall udocker
```

---

## 📊 Detail Sistem & Koneksi

| Opsi | Nama OS / App | Default User | Default Port | Mode |
|---|---|---|---|---|
| **01** | **Ubuntu 22.04** | `root` | `2223` | SSH |
| **02** | **Debian 12** | `root` | `2224` | SSH |
| **03** | **Kali NetHunter** | `root` | `2222` | SSH |
| **04** | **Kali Linux (Minimal)** | `root` | `2222` | SSH |
| **05** | **JupyterLab / Dev** | — | `8888` | Web |
| **06** | **CLI Command** | — | — | Submenu |
| **07** | **Google Project** | — | — | Submenu |

### 🔑 Akses Default:
- **SSH Password:** `ubuntu`, `debian`, `kali`, atau `nethunter`
- **VNC Password:** `vncpass`

---

## 📂 Struktur Direktori

```
~/.roc-containers/
├── setup.sh              # Installer + command linker
├── menu.sh               # Menu interaktif
├── install_udocker.sh    # udocker installer
├── start.sh              # Quick start
├── push.sh               # Git push helper
├── bin/                  # Binary wrappers
├── lib/
│   ├── source.env        # Shared env & udocker helpers
│   ├── cli_command.sh    # CLI submenu
│   ├── google_project.sh # GCP submenu
│   ├── manager.sh        # Container manager
│   ├── sysinfo.sh        # System info
│   ├── uninstall.sh      # Uninstaller
│   └── update.sh         # Updater
├── os/
│   ├── ubuntu/           # Ubuntu container
│   ├── debian/           # Debian container
│   ├── kali/             # Kali container
│   └── nethunter/        # NetHunter container
└── apps/
    ├── roc-agent/        # AI Agent CLI (roc-agentsroute)
    ├── hermes-agent/     # Hermes Agent (container, root)
    ├── crewai/           # CrewAI
    ├── jupyter/          # JupyterLab
    ├── antigravity/      # Google AI IDE
    ├── adk-invoice/      # ADK Invoice
    ├── tailscale/        # Tailscale VPN
    ├── httpd/            # HTTP Server
    ├── redis/            # Redis
    ├── ros/              # ROS
    └── calibre-web/      # Calibre e-books
```

---

## 🔧 Related Repos

| Repo | Fungsi |
|---|---|
| [roc-containers](https://github.com/ivansslo/roc-containers) | Container manager (ini) |
| [roc-agentsroute](https://github.com/ivansslo/roc-agentsroute) | AI Agent CLI utama |

---

## 📜 License

MIT License · Created by **ivansslo** · 2026
