# ⚡ roc-containers

**AI Agent CLI + App Manager for Termux (native)** — hermes CLI, lsmod v2 module system, RoadFX AI stack, dan tool native lainnya. Dibuat oleh **ivansslo** (2026) · **License: MIT**.

> **v1.5.0 — Native Only.** Semua command berbasis container **telah dihapus**
> (`roc-ubuntu`, `roc-debian`, `roc-httpd`, `roc-tailscale`, `roc-hms`,
> `roc-crewai`, `roc-adk`, `roc-antigravity`). udocker tetap tersedia untuk
> menjalankan container **manual berdasarkan nama**: `udocker run <nama>`.
> Lihat [Changelog](#-changelog).

---

## 🚀 Quick Install (Termux)

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

### ⭐ AI Stack (Primary)
| Command | Fungsi |
|---|---|
| `roc-ai` | ⭐ RoadFX AI Stack — ivansslo/roadfx-ai-stack |
| `roc-ai orchestrator <task>` | 🧠 Autonomous Orchestrator — Planner→Researcher→Coder→Reviewer→Tester + Grounding (AIS-DEV + Gateway first-class) |
| `roc-ai mesh` | 🕸️ Native Service Mesh — status layanan native |

### lsmod v2 (native module system)
| Command | Fungsi |
|---|---|
| `roc-ai agent <task>` | 🤖 Agent mode |
| `roc-ai chat` | 💬 Chat interaktif |
| `roc-ai code <task>` | 💻 Coding assistant |
| `roc-ai error <msg>` | 🐛 Error handler / fix |
| `roc-ai route <task>` | 🧭 Auto-route ke modul terbaik |
| `roc-ai broadcast <msg>` | 📢 Broadcast ke registry modul |
| `roc-ai orchestrate <task>` | 🎼 Koordinasi multi-agent native |
| `roc-ai registry` | 📦 Daftar modul (registry formal v2) |

### 🤖 AI & Apps (native)
| Command | Fungsi |
|---|---|
| `roc-agent` | AI Agent CLI utama — Hermes v5.12.0 "Oracle" |
| `roc-maagba` | Multi-Agent Architectural Guidance (Bedrock AgentCore) |
| `roc-spwr` | Superpowers (coding agent skills) |
| `roc-hermui` | Hermes UI (dashboard bundel roc-agentsroute) |
| `roc-clawdex` | Clawdex Mobile (ivansslo/clawdex-mobile) |

### ⚙️ System
| Command | Fungsi |
|---|---|
| `roc-menu` | Menu interaktif utama |
| `roc-status` | Status containers udocker yang ADA (run manual) |
| `roc-gcp` | Google Cloud tools (Gemini/Vertex creds) |
| `roc-sysinfo` | System info (RAM/CPU) |
| `roc-update` | Update roc-containers |
| `roc-uninstall` | Uninstall / clean |
| `roc-udocker` | Install/repair udocker |
| `roc-remote` | 🌐 Remote dev connect (Codespaces/CloudShell/Oracle/Aiven/Solace) |

### 🐳 Container? Manual saja (v1.5.0)
Perintah container tidak lagi dikelola roc-*. Jalankan langsung pakai **nama container**:

```bash
udocker pull ubuntu:22.04
udocker create --name=ubuntu ubuntu:22.04
udocker run ubuntu            # ← perintah = nama container
roc-status                    # lihat container yang ada
```

---

## 🔑 Setup API Keys

```bash
# Interactive
roc-agent setup

# Atau manual
cat > ~/.hermes_keys << 'EOF'
GROQ_KEY=gsk_xxxxxx
GEMINI_KEY=AIzaSxxxxxx
OR_KEY=sk-or-xxxxxx
OPENAI_KEY=sk-xxxxxx
TOKEN=hk-xxxxxx
EOF
chmod 600 ~/.hermes_keys
```

> ⚠️ **Jangan pernah hardcode keys di source code.** Semua keys di-load dari env
> (`~/.hermes_keys` / `~/.hermes/.keys`).

---

## 📂 Struktur Direktori (v1.5.0)

```
~/.roc-containers/
├── setup.sh              # Installer + command linker
├── menu.sh               # Menu interaktif (native)
├── start.sh              # Quick start → menu
├── push.sh               # Safe-push via GitHub CLI (tanpa token tempel)
├── install_udocker.sh    # udocker installer
├── lib/
│   ├── source.env        # Shared env + palet warna + udocker helpers
│   ├── lsmod_loader.sh   # lsmod v2 shared loader + registry
│   ├── google_project.sh # GCP submenu
│   ├── gcp_provider.sh   # Gemini/Vertex creds checker
│   ├── manager.sh        # Container status (udocker minimal)
│   ├── sysinfo.sh        # System info
│   ├── uninstall.sh      # Uninstaller
│   ├── update.sh         # Updater
│   ├── remote-connect.sh # Remote dev connect
│   ├── pyhttp.sh         # python http.server helper
│   └── cloud-init.sh     # Cloud VM bootstrap
├── ui/
│   └── roc-containers-ui.html  # Preview menu (native)
└── apps/
    ├── ai/               # ⭐ RoadFX AI Stack + lsmod v2
    ├── roc-agent/        # Hermes CLI ter-bundle (v5.12.0 + dashboard)
    ├── maagba/           # MAAGBA (Bedrock AgentCore)
    ├── spwr/             # Superpowers
    ├── hermui/           # Hermes UI (fallback dashboard bundel)
    └── clawdex/          # Clawdex Mobile
```

---

## 🗄️ Infrastructure (ecosystem)

| Service | Provider | Status |
|---|---|---|
| Gateway (hermes-cloudflare) | Cloudflare Workers | v18.0.3 · 16 models · 31 secret bindings |
| roc-site (16 domains) | Cloudflare Workers | v18.0.3 · unified router |
| PostgreSQL | Aiven (`pg-roadfx`) | AWS ap-southeast-3 |
| Solace PubSub+ | Solace Cloud | Singapore · 5 queues |
| Oracle VM (WebVirtCloud) | Oracle ap-singapore-1 | 5 services · `vm.roadfx.biz.id` |
| Firebase | planning-with-ai-36675 + yttriferous | Auth + Firestore |
| AI Studio App | Google AI Studio | alias: rocspace.ai.studio 🔒 (private) |

---

## 🔧 Related Repos

| Repo | Isi |
|---|---|
| [rocspace](https://github.com/ivansslo/rocspace) | RocSpace Monorepo — CF Workers v18.0.3 |
| [roc-agentsroute](https://github.com/ivansslo/roc-agentsroute) | Hermes AI Agent CLI v5.12.0 |
| [roadfx-ai-stack](https://github.com/ivansslo/roadfx-ai-stack) | RoadFX AI Stack (roc-ai) |
| [clawdex-mobile](https://github.com/ivansslo/clawdex-mobile) | Clawdex Mobile |
| [hermes-agent](https://github.com/ivansslo/hermes-agent) | Hermes Agent upstream |

---

## 📜 License

MIT License · Created by **ivansslo** · 2026

---

## 🆕 Changelog

### v1.5.0 — Native Only + lsmod v2 (2026-07-16)

Sesuai keputusan pemilik repo: **hilangkan semua yang koneksi containers**.

**DIHAPUS (command & source berbasis container):**
- Commands: `roc-ubuntu`, `roc-debian`, `roc-httpd`, `roc-tailscale`,
  `roc-hms`, `roc-crewai`, `roc-adk`, `roc-antigravity`
- Source: `os/`, `apps/{httpd,tailscale,hms,crewai,adk-invoice,antigravity,hermes-agent}`,
  `lib/cli_command.sh`, `lib/libnetstub.sh`, `_LIBNETSTUB_*` di source.env,
  helper koneksi SSH/VNC di `manager.sh`, `preview.html` (basi)
- udocker **tetap** untuk run manual: **`udocker run <nama-container>`**
  (`roc-status` + `roc-udocker` + `roc-uninstall` dipertahankan)

**lsmod REFRESH → v2.0.0 (native):**
- ✗ `lsmod_propagate` ke container rootfs, mesh berbasis `udocker inspect` — dibuang
- ✓ **Module registry formal**: `lsmod registry` (`lib/lsmod_loader.sh` — 8 modul)
- ✓ mesh() jadi **native service mesh** (roc-agent, repos, solace env, api keys, gateway)
- ✓ `_lsmod_agent_run` fallback bundled hermes; route/broadcast native
- ✓ `roc-ai route` + `roc-ai broadcast` + `roc-ai registry` terdaftar di ai.sh

**Lainnya:**
- `menu.sh` ditulis ulang (15 opsi native, opsi 22 orchestrator dipertahankan sebagai 03)
- `google_project.sh` pangkas ke Provider GCP saja (semua launcher container dibuang)
- `ui/roc-containers-ui.html` sinkron menu v1.5.0; README ditulis ulang

### v1.4.0 — Repair Release (2026-07-16)

- **CRITICAL**: `setup.sh` 2 baris `${CYAN}` nyasar (abort `set -e` sebelum System
  commands ter-install) + escape heredoc wrapper `roc-agent` diperbaiki
- `DATA_DIR="$(pwd)/../../data-*"` di 7 script → berbasis lokasi script
- `apps/hms` → wrapper ke launcher resmi; `apps/spwr` clone ke subdir `repo/`
- `lib/manager.sh` loop `[0] Back` diperbaiki; `lib/source.env` palet warna global
- Fallback repo mati: `roc-hermui` → dashboard bundel; lsmod clone-gagal → pesan jujur
- Bundle **hermes v5.12.0** + `dashboard/`; `docs/PARAMETER-AUDIT.md`: 5 nilai rahasia direduksi
