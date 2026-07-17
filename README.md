# ⚡ roc-containers

**AI Agent CLI + App Manager for Termux (native)** — hermes CLI, lsmod v2 module system, RoadFX AI stack, dan tool native lainnya. Dibuat oleh **ivansslo** (2026) · **License: MIT**.

> **v1.6.0 — Native Only + Oracle VM + Antigravity IDE + Cloudflare Tunnel + `roc-access` + **`roc-help`**. Oracle × Tunnel digabung. Semua command berbasis container **telah dihapus**
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

### 🖥️ Oracle VM (alias: `webvirtcloud.ai.studio`)
| Command | Fungsi |
|---|---|
| `roc-vm status` | 🖥️ Status & probe semua endpoint (health/WVC/Kuma/monitor/noVNC) |
| `roc-vm console` | Buka VM Console (`vm.roadfx.biz.id/vm`, Firebase auth) |
| `roc-vm services` | Layanan aktif di VM (JSON via bridge HTTPS `vm.roadfx.biz.id/health`) |
| `roc-vm ssh` | Tampilkan perintah SSH (public IP / tailnet) |
| `roc-vm wvc / kuma / monitor / novnc` | Buka WebVirtCloud / Uptime Kuma / monitor / noVNC |
| `roc-vm studio` | Buka AI Studio app + info alias |

### 🤖 AI & Apps (native)
| Command | Fungsi |
|---|---|
| `roc-agent` | AI Agent CLI utama — Hermes v5.13.0 "Oracle" (include `antigravity` IDE ARM64) |
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

> 🧹 **Auto-cleanup (v1.5.1):** menjalankan `bash setup.sh` (atau `roc-update`)
> otomatis menghapus wrapper usang `roc-ubuntu/debian/httpd/tailscale/hms/crewai/adk/antigravity` dari `$PREFIX/bin` — tidak perlu `rm` manual.

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

## 📂 Struktur Direktori (v1.5.x)

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
    ├── roc-agent/        # Hermes CLI ter-bundle (v5.13.0 + dashboard)
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
| [roc-agentsroute](https://github.com/ivansslo/roc-agentsroute) | Hermes AI Agent CLI v5.13.0 |
| [roadfx-ai-stack](https://github.com/ivansslo/roadfx-ai-stack) | RoadFX AI Stack (roc-ai) |
| [clawdex-mobile](https://github.com/ivansslo/clawdex-mobile) | Clawdex Mobile |
| [hermes-agent](https://github.com/ivansslo/hermes-agent) | Hermes Agent upstream |

---

## 📜 License

MIT License · Created by **ivansslo** · 2026

---

## 🆕 Changelog

### v1.6.0 — Oracle × Tunnel digabung + `roc-help` + panduan OCI/Rofwin (2026-07-17)
- **Oracle × Tunnel** (`lib/tunnel.sh` sub-perintah baru, via `roc-access ssh`):
  - `roc-tunnel oracle-install` — pasang cloudflared (.deb arm64/amd64) **di VM**.
  - `roc-tunnel oracle-login` — salin `cert.pem` dari HP → VM (cert account+zone dipakai bersama; tanpa login interaktif server).
  - `roc-tunnel oracle-create` — tunnel `roc-ag-vm`: ingress **`novnc.roadfx.biz.id` → `http://localhost:6905`** + **`sshvm.roadfx.biz.id` → `ssh://localhost:22`** + DNS route otomatis.
  - `roc-tunnel oracle-up` — systemd `cloudflared-roc.service` enable+start di VM; `oracle-status` = status service + tunnel list + probe `novnc.roadfx.biz.id`.
- **Jembatan**: `roc-access tunnel` = alias langsung ke `roc-tunnel oracle-*`.
- **`roc-help`** (`lib/rochelp.sh`) — bantuan keseluruhan ekosistem dengan filter topik: `vm | tunnel | ag | ai | sys | docs | label`, tampilan berseksi + label resmi.
- **Dokumen baru** `docs/OCI-ANDROID-VM-ROFWIN.md` — setting cloud.oracle.com untuk VM Android/Rofwin: tabel Security List, plugin agent, Run Command, fakta nested-KVM & blueprint runtime Winlator-style (proot+box64/FEX+wine→noVNC→Tunnel).
- Menu opsi **27** + seksi panel UI “Oracle × Tunnel” & “Bantuan”.

### v1.5.6 — `roc-access`: SSH · VNC · RDP Oracle VM (2026-07-17)
- Wrapper **`roc-access`** (`lib/vmaccess.sh`) — satu pintu akses `webvirtcloud.ai.studio`:
  - `setup` — wizard: deteksi/buat key (`id_ed25519` → `id_oracle.key` → `id_rsa`), pilih user (`ubuntu`, bisa override), pilih jalur (`pub`/`ts`/`auto`), simpan `~/.roc-containers/vmaccess.conf` (600), cetak pubkey siap-pasang untuk OCI Run Command.
  - `ssh`/`login` — exec ssh dengan key + jalur auto (publik fallback tailnet), `IdentitiesOnly`, keepalive.
  - `status` — probe live: SSH (BatchMode `hostname`), port 80, `5905` (AG web), `6905` (AG noVNC), `3389` (RDP).
  - `vnc url|open|fwd` — noVNC `:6905` langsung / buka browser Termux / SSH tunnel `-L 6905` (tanpa buka firewall).
  - `rdp url|setup|fwd` — info koneksi + aplikasi Android; `rdp setup` = install **xrdp + dbus-x11** remote via SSH + enable service + iptables; `rdp fwd` = tunnel `-L 3389`.
- Menu opsi **23–26** + seksi panel UI baru; README/UI sinkron.

### v1.5.5 — Cloudflare Tunnel `roc-tunnel` (2026-07-17)
- Wrapper **`roc-tunnel`** (`lib/tunnel.sh`): `install | login | create | up | up-bg | down | status | url | quick`.
- Alur sekali: `roc-tunnel install` → `login` (OAuth CF di browser, sekali) → `create` (tunnel `roc-ag-hp` + ingress **`ag.roadfx.biz.id` → `http://localhost:5905`** + DNS route via cloudflared cert) → `up-bg` (nohup + pidfile + log di `~/.roc-containers/cloudflared/`).
- Override via env: `ROC_TUNNEL_NAME` · `ROC_TUNNEL_HOST` · `ROC_TUNNEL_TARGET`.
- Menu opsi **22** + seksi panel UI baru. Catatan keamanan: URL publik Antigravity tanpa Access = risiko; saran aktifkan Cloudflare Access (email OTP) di Zero Trust dashboard setelah tunnel jalan.

### v1.5.4 — Panel pintasan layanan `webvirtcloud.ai.studio` (2026-07-17)
- UI panel (`ui/roc-containers-ui.html`): seksi 🖥️ Oracle VM kini berisi **link satu-tap** langsung ke seluruh layanan — WebVirtCloud `/wvc/`, Uptime Kuma `/kuma/`, Monitor `/monitor/`, noVNC `/vm/novnc/`, plus Console Web `vm.roadfx.biz.id`.
- Melengkapi integrasi yang sudah ada: wrapper `roc-vm` (delegate `hermes vm …`), menu 16–18, probe live di `roc-vm status`.

### v1.5.3 — Label panel `antigravity.ai.studio` (2026-07-17)
- Konstanta/label resmi **`antigravity.ai.studio`** untuk Antigravity IDE — mengikuti pola `webvirtcloud.ai.studio`.
- Menu opsi baru: **19** Antigravity Status (via `hermes antigravity status`), **20** Web UI node HP (`http://localhost:5905`, auto-buka browser), **21** Node Oracle VM noVNC `:6905` (status pending sampai instalasi VM selesai).
- UI panel (`ui/roc-containers-ui.html`): seksi 🧠 Antigravity IDE dengan dua node (HP + Oracle VM).
- Hermes v5.13.1 (roc-agentsroute): panel `vm status` kini menampilkan probe **Node HP (:5905)** dan **Node VM (:6905)** + label di `antigravity status`.

### v1.5.2 — Bundle hermes v5.13.0 "Antigravity" (2026-07-16)
- Bundle `apps/roc-agent/hermes` sinkron → **v5.13.0**: command baru
  `antigravity` (alias `ag|ide`) — installer resmi **Google Antigravity IDE**
  linux/ARM64 (build `2.3.0-5214728084127744`, pinned URL + verifikasi
  content-length & MD5 GCS) + launcher GUI/`xvfb-run` + mode **headless VNC
  :5905**. Tersedia via `roc-agent antigravity install|status|launch|vnc`.
  Target run: Oracle VM (aarch64) / Termux via proot-distro (glibc).
- Bundle `apps/roc-agent/dashboard/` sinkron (badge v5.13.0 + baris cheatsheet antigravity).

### v1.5.1 — Auto-Cleanup + Oracle VM Integration (2026-07-16)
- **Auto-cleanup wrapper usang** di `setup.sh`: `roc-ubuntu/debian/httpd/tailscale/hms/crewai/adk/antigravity` otomatis dihapus dari `$BIN_DIR` saat setup/`roc-update` — tidak perlu `rm` manual lagi
- **Command baru `roc-vm`** — integrasi Oracle VM · WebVirtCloud (alias: `webvirtcloud.ai.studio`), thin wrapper → Hermes v5.12.0 "Oracle":
  - `roc-vm status` — probe health/WVC/Kuma/monitor/noVNC sekaligus
  - `roc-vm console` — buka VM Console (`vm.roadfx.biz.id/vm`)
  - `roc-vm services` — layanan aktif di VM (bridge HTTPS `vm.roadfx.biz.id/health`)
  - `roc-vm ssh / tailscale / wvc / kuma / monitor / novnc / studio`
- `menu.sh`: section baru **🖥️ Oracle VM** (opsi 16–18); `ui/roc-containers-ui.html` sinkron + link console

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
