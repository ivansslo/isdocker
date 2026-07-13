# Hermes Agent (autonomous) · roc-containers

Menjalankan **Hermes Agent** — AI agent otonom dengan *tool-using ReAct loop*
untuk **complex task** (bukan sekadar chat) — **di dalam container udocker**
(`python:3.12-slim`), **sebagai root**, memakai **Python venv** yang dipersist.

> Terinspirasi [NousResearch/hermes-agent](https://github.com/NousResearch/hermes-agent),
> tetapi engine ringan yang dibundel langsung di `apps/hermes-agent/engine`.

---

## 📦 Cara Install

Tidak ada langkah manual — instalasi **otomatis** saat pertama dijalankan.

1. Jalankan menu roc-containers:
   ```bash
   bash ~/.roc-containers/menu.sh
   ```
2. Pilih **[06] CLI Command → [1] Hermes Agent (autonomous)**.
3. Pilih **[1] Setup** (sekali saja). Container akan:
   - pull image `python:3.12-slim` (via udocker),
   - membuat **venv** di `/root/venv` (dipersist di `data-hermes-agent/root`),
   - `pip install` dependency (rich, requests, python-dotenv).

> Jalan langsung tanpa menu:
> ```bash
> bash ~/.roc-containers/apps/hermes-agent/hermes-agent.sh setup
> bash ~/.roc-containers/apps/hermes-agent/hermes-agent.sh run
> ```

Venv + workspace + engine disimpan di `data-hermes-agent/root/` sehingga
**bertahan antar-run** (tidak perlu install ulang).

---

## 🚀 Cara Penggunaan

| Perintah | Keterangan |
|---|---|
| `setup` | Buat venv + install dependency (root) |
| `run [task]` | Jalankan agent — REPL interaktif bila tanpa task |
| `agent [task]` | Alias dari `run` |
| `version` | Versi engine + Python |
| `shell` | Masuk shell container (root, venv aktif) |
| `tailscale` | Cek kecocokan CLI Tailscale di container agent |

Contoh:
```bash
hermes-agent run "buat FastAPI todo + pytest, buat semua test hijau"
hermes-agent run "clone repo X, tambah Dockerfile, pastikan bisa di-build"
PROVIDER=openrouter MODEL=deepseek/deepseek-chat hermes-agent run "refactor app.py"
```

Semua operasi file/shell diarahkan ke workspace sandbox `/root/workspace`
di dalam container.

---

## 🧰 Tool yang dimiliki agent

`run_shell`, `read_file`, `write_file`, `edit_file`, `list_dir`,
`python_exec`, `http_get`, `finish` — agent memakainya dalam loop hingga
tugas selesai & terverifikasi.

---

## 🔑 Kredensial

Kunci API dibaca dari **`~/.hermes_keys`** (berbagi dengan CrewAI & Google
Project di roc-containers). Yang didukung:

| Provider | Var di `~/.hermes_keys` | Default model |
|---|---|---|
| `groq` (default) | `GROQ_KEY` / `GROQ_API_KEY` | `llama-3.3-70b-versatile` |
| `openrouter` | `OR_KEY` / `OPENROUTER_KEY` | `google/gemini-2.5-flash` |
| `gemini`* | `GEMINI_API_KEY` | `gemini-2.5-flash` |
| `openai` | `OPENAI_API_KEY` | `gpt-4o-mini` |
| `gateway`/`cloudrun` | `TOKEN` | `llama-3.3-70b-versatile` |

Pilih provider/model per-run lewat env:
```bash
PROVIDER=openrouter MODEL=deepseek/deepseek-chat hermes-agent run "..."
```

> Gunakan model yang mendukung **function calling** (Llama-3.3-70B, GPT-4o,
> DeepSeek, Gemini, Qwen) untuk hasil terbaik.

---

## 🔗 Kecocokan dengan Tailscale CLI

Pertanyaan umum: *"apakah CLI Tailscale bisa cocok?"* — **Ya.**

Container agent memakai `python:3.12-slim` (**Debian 12 bookworm**), sama basis
Debian seperti app **Tailscale roc-containers** (menu CLI [3]). Repo resmi Tailscale
(`pkgs.tailscale.com/stable/debian/bookworm`) + `apt install tailscale` +
`tailscaled --tun=userspace-networking` berjalan penuh (tanpa `/dev/net/tun`).

Verifikasi langsung:
```bash
hermes-agent tailscale
```
Skrip `tailscale_check.sh` akan:
1. cek arsitektur (arm64/amd64 didukung Tailscale),
2. install + jalankan `tailscale version` / `--help` di container agent,
3. konfirmasi subcommand `up` / `status` / `ip`,
4. cek mode userspace-networking,
5. **berbagi state login** dengan node dari menu CLI [3] bila ada
   (`data-tailscale-node/state`).

Artinya agent bisa memanggil `tailscale` lewat tool `run_shell` — mis. agent
menaikkan node, membaca `tailscale ip`, lalu bekerja lewat jaringan tailnet.

---

## ⚠️ Catatan

- Agent **menjalankan perintah nyata** sebagai **root di dalam container**
  (terisolasi dari host Termux). Isolasi udocker menjaga host tetap aman.
- Core engine hanya butuh **standard library**, jadi tetap jalan walau
  `pip install` dependency opsional gagal.
- Data & venv persist di `data-hermes-agent/` (di-`.gitignore` oleh roc-containers).
