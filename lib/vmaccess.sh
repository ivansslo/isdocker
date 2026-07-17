#!/usr/bin/env bash
# lib/vmaccess.sh — Akses Oracle VM  (alias: webvirtcloud.ai.studio)
# Subcommand: setup | login | ssh | status | vnc [url|open|fwd] | rdp [setup|url|fwd] | help
# Config: ~/.roc-containers/vmaccess.conf (chmod 600) — dibuat oleh `roc-access setup`.
set -uo pipefail

CONF_DIR="$HOME/.roc-containers"
CONF="$CONF_DIR/vmaccess.conf"

# default (boleh dioverride oleh vmaccess.conf / env)
VM_USER="${VM_USER:-ubuntu}"
VM_IP_PUB="${VM_IP_PUB:-161.118.253.28}"
VM_IP_TS="${VM_IP_TS:-100.93.139.73}"
VM_KEY="${VM_KEY:-}"
VM_PREF="${VM_PREF:-pub}"        # pub | ts | auto
AG_WEB_PORT="${AG_WEB_PORT:-5905}"    # antigravity web (launcher)
AG_NOVNC_PORT="${AG_NOVNC_PORT:-6905}" # antigravity noVNC VNC (systemd noVNC)
VM_WVC_NOVNC="http://$VM_IP_PUB/vm/novnc/"
RDP_PORT="${RDP_PORT:-3389}"
LABEL="webvirtcloud.ai.studio"

[ -f "$CONF" ] && . "$CONF"

G='\033[0;32m'; Y='\033[1;33m'; R='\033[0;31m'; C='\033[0;36m'; B='\033[1m'; D='\033[2m'; N='\033[0m'
ok(){   printf "  ${G}[✓]${N} %s\n" "$*"; }
warn(){ printf "  ${Y}[!]${N} %s\n" "$*"; }
err(){  printf "  ${R}[✗]${N} %s\n" "$*"; }
note(){ printf "  ${D}%s${N}\n" "$*"; }
hd(){   printf "\n${B}%s${N}\n" "$*"; }

pick_key(){
  if [ -n "$VM_KEY" ] && [ -f "$VM_KEY" ]; then echo "$VM_KEY"; return 0; fi
  local k
  for k in "$HOME/.ssh/id_ed25519" "$HOME/.ssh/id_oracle.key" "$HOME/.ssh/id_rsa" "$HOME/.ssh/oci_api_key.pem"; do
    [ -f "$k" ] && { echo "$k"; return 0; }
  done
  return 1
}

tcp_open(){ # tcp_open host port → 0 jika SYN sukses
  timeout 4 bash -c "echo > /dev/tcp/$1/$2" 2>/dev/null
}

pick_host(){
  case "$VM_PREF" in
    pub) echo "$VM_IP_PUB" ;;
    ts)  echo "$VM_IP_TS" ;;
    auto|*)
      if tcp_open "$VM_IP_PUB" 22; then echo "$VM_IP_PUB"
      elif tcp_open "$VM_IP_TS" 22; then echo "$VM_IP_TS"
      else echo "$VM_IP_PUB"; fi ;;
  esac
}

ssh_base(){
  local key; key="$(pick_key)" || return 1
  echo "ssh -i $key -o IdentitiesOnly=yes -o StrictHostKeyChecking=accept-new -o ConnectTimeout=10 -o ServerAliveInterval=30 $VM_USER@$(pick_host)"
}

cmd_setup(){
  hd "🔧 Setup akses VM — $LABEL"
  mkdir -p "$CONF_DIR"; chmod 700 "$CONF_DIR"
  # key
  local key; key="$(pick_key || true)"
  if [ -z "$key" ]; then
    warn "tidak ada key SSH — membuat baru ~/.ssh/id_ed25519"
    ssh-keygen -t ed25519 -f "$HOME/.ssh/id_ed25519" -N "" -C "termux@$(uname -o 2>/dev/null || echo android)" || return 1
    key="$HOME/.ssh/id_ed25519"
  fi
  ok "key: $key"
  # preferensi jalur
  printf "  Jalur koneksi: [1] IP publik %s  [2] tailnet %s  [3] auto (rekomendasi) : " "$VM_IP_PUB" "$VM_IP_TS"
  read -r pilih
  case "$pilih" in
    1) VM_PREF=pub ;; 2) VM_PREF=ts ;; *) VM_PREF=auto ;;
  esac
  printf "  SSH user VM [default: %s]: " "$VM_USER"; read -r u; [ -n "$u" ] && VM_USER="$u"
  cat > "$CONF" <<EOF
VM_USER="$VM_USER"
VM_IP_PUB="$VM_IP_PUB"
VM_IP_TS="$VM_IP_TS"
VM_KEY="$key"
VM_PREF="$VM_PREF"
AG_WEB_PORT="$AG_WEB_PORT"
AG_NOVNC_PORT="$AG_NOVNC_PORT"
RDP_PORT="$RDP_PORT"
EOF
  chmod 600 "$CONF"
  ok "config disimpan → $CONF (600)"
  echo ""
  note "kalau SSH masih 'Permission denied': pubkey kamu belum ada di VM."
  note "tempel pubkey ini di OCI Run Command / sesi VM:"
  printf "  ${C}%s${N}\n" "$(cat "$key.pub" 2>/dev/null)"
  echo ""
  cmd_status
}

cmd_login(){ cmd_ssh "$@"; }
cmd_ssh(){
  local base; base="$(ssh_base)" || { err "tidak ada key — jalankan: roc-access setup"; exit 1; }
  note "exec: $base $*"
  exec $base "$@"
}

_cmd_try(){ # jalankan remote command via ssh (non-exec, tangkap output)
  local base; base="$(ssh_base)" || return 1
  $base -o BatchMode=yes "$@"
}

probe_ssh(){
  local base out; base="$(ssh_base)" || { printf "    ${R}●${N} %-14s ${R}no key${N}\n" "ssh"; return 1; }
  out=$($base -o BatchMode=yes hostname 2>/dev/null)
  if [ -n "$out" ]; then printf "    ${G}●${N} %-14s ${G}OK${N} ${D}%s → %s@%s${N}\n" "ssh" "$out" "$VM_USER" "$(pick_host)"; return 0; fi
  printf "    ${R}●${N} %-14s ${R}gagal${N} ${D}%s (key? Run Command?)${N}\n" "ssh" "$(pick_host)"; return 1
}

cmd_status(){
  hd "🔑 Status akses VM — $LABEL"
  echo -e "  ${C}user:${N} $VM_USER   ${C}key:${N} $(pick_key || echo '—')   ${C}jalur:${N} $VM_PREF → $(pick_host)"
  echo -e "  ${B}Live probe:${N}"
  probe_ssh || true
  for svc in "http:80" "ag-web:$AG_WEB_PORT" "ag-novnc:$AG_NOVNC_PORT" "rdp:$RDP_PORT"; do
    n="${svc%%:*}"; po="${svc##*:}"
    if tcp_open "$(pick_host)" "$po"; then printf "    ${G}●${N} %-14s ${G}open${N}\n" "$n"; else printf "    ${R}●${N} %-14s ${R}tutup${N}\n" "$n"; fi
  done
  echo ""
  note "ssh → roc-access ssh · vnc → roc-access vnc · rdp → roc-access rdp"
}

cmd_vnc(){
  local a="${1:-url}"
  case "$a" in
    url)
      hd "🖥️  VNC/noVNC — $LABEL"
      echo -e "  ${C}Antigravity noVNC (VM):${N}  http://$VM_IP_PUB:$AG_NOVNC_PORT/vnc.html"
      echo -e "  ${C}via tailnet:${N}             http://$VM_IP_TS:$AG_NOVNC_PORT/vnc.html"
      echo -e "  ${C}WVC noVNC (console):${N}    $VM_WVC_NOVNC"
      note "kalau port 6905 belum tampak: install antigravity di VM dulu, atau pakai 'roc-access vnc fwd'"
      ;;
    open)
      local url="http://$VM_IP_PUB:$AG_NOVNC_PORT/vnc.html"
      note "buka: $url"
      if command -v termux-open-url &>/dev/null; then termux-open-url "$url"
      elif command -v am &>/dev/null; then am start -a android.intent.action.VIEW -d "$url" 2>/dev/null || true
      else echo "Buka manual: $url"; fi ;;
    fwd)
      local base; base="$(ssh_base)" || { err "tidak ada key — roc-access setup"; exit 1; }
      hd "🖥️  VNC via SSH tunnel (aman, tanpa buka firewall)"
      note "tetap jalankan sesi ini; lalu buka: http://localhost:$AG_NOVNC_PORT/vnc.html"
      exec $base -N -L "$AG_NOVNC_PORT:localhost:$AG_NOVNC_PORT" ;;
    *) err "subcommand: vnc [url|open|fwd]"; exit 1 ;;
  esac
}

cmd_rdp(){
  local a="${1:-url}"
  case "$a" in
    url)
      hd "🪟 RDP — $LABEL"
      echo -e "  ${C}Host:${N} $VM_IP_PUB:$RDP_PORT  (atau tailnet $VM_IP_TS:$RDP_PORT)"
      echo -e "  ${C}User:${N} $VM_USER ${D}(password OS — set dulu: sudo passwd $VM_USER)${N}"
      note "aplikasi Android: Microsoft Remote Desktop / aRDP — tambah PC → alamat di atas"
      note "kalau port tertutup: 'roc-access rdp setup' (install xrdp di VM) atau 'roc-access rdp fwd'"
      ;;
    setup)
      hd "🪟 Setup xrdp di VM (via SSH)"
      note "menjalankan remote: apt install xrdp + enable + buka port lokal"
      _cmd_try 'sudo apt-get update -y -qq && sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq xrdp dbus-x11 && echo "startxfce4" | sudo tee /etc/skel/.xsession >/dev/null 2>&1; sudo systemctl enable --now xrdp && sudo iptables -C INPUT -p tcp --dport 3389 -j ACCEPT 2>/dev/null || sudo iptables -I INPUT -p tcp --dport 3389 -j ACCEPT; echo RDP-SIAP'
      ok "xrdp aktif di VM (bila remote sukses) — uji: roc-access rdp url"
      warn "jangan lupa buka tcp 3389 di OCI Security List bila akses dari internet, ATAU pakai 'roc-access rdp fwd' (lebih aman)"
      ;;
    fwd)
      local base; base="$(ssh_base)" || { err "tidak ada key — roc-access setup"; exit 1; }
      hd "🪟 RDP via SSH tunnel (rekomendasi aman)"
      note "tetap jalankan sesi ini; di aplikasi RDP Android sambung ke: localhost:$RDP_PORT"
      exec $base -N -L "$RDP_PORT:localhost:$RDP_PORT" ;;
    *) err "subcommand: rdp [setup|url|fwd]"; exit 1 ;;
  esac
}

case "${1:-help}" in
  setup) cmd_setup ;;
  ssh|login) shift || true; cmd_ssh "$@" ;;
  status|st) cmd_status ;;
  vnc) shift || true; cmd_vnc "${1:-url}" ;;
  rdp) shift || true; cmd_rdp "${1:-url}" ;;
  tunnel)
    # jembatan ke roc-tunnel sub-oracle (gabungan Oracle × Tunnel)
    shift || true
    _LIB_TUN="$CONF_DIR/lib/tunnel.sh"
    if [ -f "$_LIB_TUN" ]; then exec bash "$_LIB_TUN" "oracle-${1:-status}"
    else err "lib/tunnel.sh belum ada — roc-update"; exit 1; fi ;;
  *)
    echo -e "${B}roc-access${N} — akses Oracle VM ($LABEL)"
    echo "  setup              wizard key + user + jalur + simpan config"
    echo "  ssh | login        masuk shell VM (auto key+jalur)"
    echo "  status             probe SSH/80/$AG_WEB_PORT/$AG_NOVNC_PORT/$RDP_PORT"
    echo "  vnc url|open|fwd   noVNC :$AG_NOVNC_PORT (langsung / buka browser / SSH tunnel)"
    echo "  rdp url|setup|fwd  RDP :$RDP_PORT (info / install xrdp di VM / SSH tunnel)"
    echo "  tunnel             alias → roc-tunnel oracle-* (cloudflared di VM)"
    echo ""
    note "config: $CONF · label: $LABEL"
    ;;
esac
