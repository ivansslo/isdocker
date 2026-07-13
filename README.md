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

### ⭐ AI Stack (Primary)
| Command | Fungsi |
|---|---|
| `roc-ai` | ⭐ **RoadFX AI Stack** — ivansslo/roadfx-ai-stack |

### 🤖 AI & Agent
| Command | Fungsi |
|---|---|
| `roc-agent` | AI Agent CLI utama — chat, ask, code, agent |
| `roc-crewai` | CrewAI multi-agent (Groq/Gemini) |
| `roc-hms` | Hermes Agent (container, root) |
| `roc-antigravity` | Antigravity AI IDE (port 5905) |
| `roc-adk` | ADK Invoice Processing (port 8000) |
| `roc-maagba` | Multi-Agent Architectural Guidance (Bedrock AgentCore) |

### 🐧 OS Containers
| Command | Fungsi |
|---|---|
| `roc-ubuntu` | Ubuntu 22.04 (port 2223) |
| `roc-debian` | Debian 12 (port 2224) |

### 🌐 Network & Services
| Command | Fungsi |
|---|---|
| `roc-tailscale` | Tailscale VPN (container node) |
| `roc-httpd` | HTTP Server (port 3000) |
| `roc-spwr` | Superpowers (coding agent skills) |
| `roc-hermui` | Hermes UI (ivansslo/hermes-ui) |
| `roc-clawdex` | Clawdex Mobile (ivansslo/clawdex-mobile) |

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
OPENAI_KEY=sk-xxxxxx
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
 ║       roc-containers · Termux Container Manager      ║
 ╚══════════════════════════════════════════════════════╝

 ── ⭐ AI Stack (Primary) ──
 [01] RoadFX AI Stack              → roc-ai

 ── 🤖 AI & Agent ──
 [02] AI Agent CLI                 → roc-agent
 [03] CrewAI Multi-Agent           → roc-crewai
 [04] Hermes Agent (container)     → roc-hms
 [05] Antigravity AI IDE           → port 5905
 [06] ADK Invoice Processing       → port 8000
 [07] MAAGBA (Bedrock AgentCore)   → roc-maagba

 ── 🐧 Operating Systems ──
 [08] Ubuntu 22.04 LTS             → port 2223
 [09] Debian 12 Bookworm           → port 2224

 ── 🌐 Network & Services ──
 [10] Tailscale VPN                → roc-tailscale
 [11] HTTP Server                  → port 3000
 [12] Superpowers (agent skills)   → roc-spwr
 [13] Hermes UI                    → roc-hermui
 [14] Clawdex Mobile               → roc-clawdex

 ── ⚙️ System ──
 [15] Container Manager (Status)
 [16] Google Cloud (GCP)
 [17] System Info (RAM/CPU)
 [18] Update roc-containers
 [19] Uninstall / Clean
 [20] Reinstall udocker
```

---

## ⭐ roc-ai — RoadFX AI Stack

**Command utama** — AI service container yang selalu up-to-date:

| Sub-command | Fungsi |
|---|---|
| `roc-ai` | Lihat help |
| `roc-ai install` | Clone repo + install dependencies |
| `roc-ai run` | Start AI stack services |
| `roc-ai status` | Cek semua services & API keys |
| `roc-ai update` | Force update ke versi terbaru |
| `roc-ai docs` | Lihat README |
| `roc-ai list` | List isi repo |
| `roc-ai shell` | Buka shell di repo dir |

Fitur:
- **Auto-update**: Cek update otomatis setiap 1 jam saat `roc-ai run`
- **Service status**: `roc-ai status` menampilkan repo, Python, Node, Docker, containers, dan API keys
- **Always current**: `roc-ai update` pull + re-install deps

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
│   └── debian/           # Debian container
└── apps/
    ├── ai/               # ⭐ RoadFX AI Stack (primary)
    ├── roc-agent/        # AI Agent CLI (roc-agentsroute)
    ├── hermes-agent/     # Hermes Agent engine
    ├── crewai/           # CrewAI
    ├── hms/              # Hermes Agent (container)
    ├── antigravity/      # Antigravity AI IDE
    ├── adk-invoice/      # ADK Invoice
    ├── maagba/           # MAAGBA (Bedrock AgentCore)
    ├── tailscale/        # Tailscale VPN
    ├── httpd/            # HTTP Server
    ├── spwr/             # Superpowers
    ├── hermui/           # Hermes UI
    └── clawdex/          # Clawdex Mobile
```

---

## 🔧 Related Repos

| Repo | Fungsi |
|---|---|
| [roc-containers](https://github.com/ivansslo/roc-containers) | Container manager (ini) |
| [roc-agentsroute](https://github.com/ivansslo/roc-agentsroute) | AI Agent CLI utama |
| [roadfx-ai-stack](https://github.com/ivansslo/roadfx-ai-stack) | ⭐ RoadFX AI Stack |
| [clawdex-mobile](https://github.com/ivansslo/clawdex-mobile) | Clawdex Mobile |
| [hermes-ui](https://github.com/ivansslo/hermes-ui) | Hermes UI |
| [spwr](https://github.com/ivansslo/spwr) | Superpowers |

---

## 📜 License

MIT License · Created by **ivansslo** · 2026
