#!/data/data/com.termux/files/usr/bin/bash
# ─────────────────────────────────────────────────────────────────
#  Created by: ivansslo (2026)
#  License: MIT
#  Repo: https://github.com/ivansslo/isdocker
# ─────────────────────────────────────────────────────────────────
#  push.sh · Aman-push repo ini ke GitHub memakai GitHub CLI (gh)
#
#  Alur:
#    1. Pastikan gh terpasang (pasang otomatis di Termux bila perlu)
#    2. Pastikan gh sudah login (kalau belum → login via browser)
#    3. gh auth setup-git  (git pakai kredensial gh, tanpa token tempel)
#    4. Set/tambah remote origin
#    5. pull --rebase, lalu push
#
#  CATATAN KEAMANAN:
#    Script ini TIDAK PERNAH meminta / menyimpan / mencetak token.
#    Autentikasi ditangani sepenuhnya oleh `gh` (disimpan terenkripsi).
#    Jangan pernah menempel token (ghp_...) di terminal / chat.
# ─────────────────────────────────────────────────────────────────
set -e

REPO_SLUG="ivansslo/isdocker"
REMOTE_URL="https://github.com/${REPO_SLUG}.git"
BRANCH="${1:-main}"

# ── Colors ──────────────────────────────────────────────────────
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'
CYAN='\033[0;36m'; DIM='\033[2m'; BOLD='\033[1m'; RESET='\033[0m'

info(){ echo -e "${CYAN}[*]${RESET} $*"; }
ok(){   echo -e "${GREEN}[✓]${RESET} $*"; }
warn(){ echo -e "${YELLOW}[!]${RESET} $*"; }
err(){  echo -e "${RED}[✗]${RESET} $*" >&2; }

# Pindah ke folder script (root repo)
cd "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "${BOLD}${CYAN}"
echo "  ╔══════════════════════════════════════════════════════╗"
echo "  ║          isdocker · Safe Push (via GitHub CLI)       ║"
echo "  ╚══════════════════════════════════════════════════════╝"
echo -e "${RESET}"

# ── 0. Pastikan ini repo git ────────────────────────────────────
if [ ! -d .git ]; then
  err "Folder ini bukan repo git (.git tidak ditemukan)."
  err "Jalankan push.sh dari dalam folder repo isdocker."
  exit 1
fi

# ── 1. Pastikan gh terpasang ────────────────────────────────────
if ! command -v gh >/dev/null 2>&1; then
  warn "GitHub CLI (gh) belum terpasang."
  if command -v pkg >/dev/null 2>&1; then
    info "Memasang gh via pkg (Termux)..."
    pkg install gh -y
  elif command -v apt-get >/dev/null 2>&1; then
    info "Memasang gh via apt..."
    sudo apt-get update -qq && sudo apt-get install -y gh
  else
    err "Tidak bisa memasang gh otomatis. Pasang manual: https://cli.github.com/"
    exit 1
  fi
fi
ok "gh tersedia: $(gh --version | head -1)"

# ── 2. Pastikan sudah login ─────────────────────────────────────
if ! gh auth status >/dev/null 2>&1; then
  warn "Belum login ke GitHub."
  info "Membuka login via BROWSER (cara paling aman — tanpa token tempel)."
  echo -e "${DIM}    Pilih: GitHub.com → HTTPS → Login with a web browser${RESET}"
  gh auth login
fi
ok "Login GitHub aktif: $(gh api user --jq .login 2>/dev/null || echo 'ok')"

# ── 3. Sinkronkan git dengan kredensial gh ──────────────────────
info "Menyetel git agar memakai kredensial gh (gh auth setup-git)..."
gh auth setup-git
ok "git credential helper diarahkan ke gh."

# ── 4. Remote origin ────────────────────────────────────────────
if git remote get-url origin >/dev/null 2>&1; then
  git remote set-url origin "$REMOTE_URL"
  info "Remote 'origin' diperbarui → $REMOTE_URL"
else
  git remote add origin "$REMOTE_URL"
  info "Remote 'origin' ditambahkan → $REMOTE_URL"
fi

# ── 5. Cek working tree bersih ──────────────────────────────────
if [ -n "$(git status --porcelain)" ]; then
  warn "Ada perubahan yang belum di-commit:"
  git status -s
  echo ""
  read -r -p "  Commit semua perubahan ini dulu? [y/N]: " yn
  if [ "${yn,,}" = "y" ]; then
    read -r -p "  Pesan commit: " msg
    [ -z "$msg" ] && msg="Update isdocker"
    git add -A
    git commit -m "$msg"
    ok "Perubahan di-commit."
  else
    warn "Melewati commit — hanya push commit yang sudah ada."
  fi
fi

# ── 6. Pull --rebase lalu push ──────────────────────────────────
info "Menyinkronkan dengan remote (pull --rebase origin $BRANCH)..."
git pull --rebase origin "$BRANCH" || warn "pull dilewati (remote/branch mungkin belum ada)."

info "Push ke origin/$BRANCH ..."
if git push -u origin "$BRANCH"; then
  echo ""
  ok "Berhasil push ke ${REPO_SLUG} (branch: $BRANCH)."
  echo -e "  ${DIM}Lihat: https://github.com/${REPO_SLUG}${RESET}"
else
  err "Push gagal. Cek koneksi / hak akses repo, lalu ulangi."
  exit 1
fi
