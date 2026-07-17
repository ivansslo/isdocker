#!/usr/bin/env bash
# lib/rochelp.sh — `roc-help` — bantuan keseluruhan ROC ecosystem
# roc-help [vm|tunnel|ag|ai|sys|docs|label]
set -uo pipefail

G='\033[0;32m'; Y='\033[1;33m'; C='\033[0;36m'; B='\033[1m'; D='\033[2m'; U='\033[4m'; N='\033[0m'
SEC(){ printf "\n${B}${C}══ %s ══${N}\n" "$*"; }
ROW(){ printf "  ${B}%-28s${N} %s\n" "$1" "$2"; }
NOTE(){ printf "  ${D}%s${N}\n" "$*"; }
BANNER(){
  printf "${B}"
  cat <<'EOF'
   ___  ___   ___     ROC Help — Pusat Bantuan Ekosistem
  | _ \/ _ \ / __|    ivansslo · Termux + Oracle VM + Cloudflare
  |   / (_) | (_ |    label: webvirtcloud.ai.studio · antigravity.ai.studio
  |_|_\\___/ \___|    v1.6.0
EOF
  printf "${N}"
}

show_vm(){ SEC "🖥️  Oracle VM — webvirtcloud.ai.studio"
  ROW "roc-vm status"      "probe live health/WVC/kuma/monitor/noVNC"
  ROW "roc-vm console"     "buka console web (vm.roadfx.biz.id)"
  ROW "roc-vm services"    "daftar layanan dari /health"
  ROW "roc-access setup"   "wizard key+user+jalur (sekali saja)"
  ROW "roc-access ssh"     "masuk shell VM (auto key, pub→ts fallback)"
  ROW "roc-access status"  "probe SSH/80/5905/6905/3389"
  ROW "roc-access vnc fwd" "noVNC :6905 lewat SSH tunnel (aman)"
  ROW "roc-access rdp setup" "install xrdp di VM (butuh SSH jalan)"
  ROW "roc-access rdp fwd" "RDP :3389 lewat SSH tunnel"
}
show_tunnel(){ SEC "🌐 Cloudflare Tunnel — roc-tunnel"
  ROW "roc-tunnel install" "pkg install cloudflared"
  ROW "roc-tunnel login"   "OAuth CF sekali (browser HP)"
  ROW "roc-tunnel create"  "tunnel HP: ag.roadfx.biz.id → localhost:5905"
  ROW "roc-tunnel up-bg"   "jalan background (nohup+log+pid)"
  ROW "roc-tunnel status"  "ringkasan + probe URL"
  ROW "── gabung Oracle ──" ""
  ROW "roc-tunnel oracle-install" "pasang cloudflared DI VM (via roc-access ssh)"
  ROW "roc-tunnel oracle-login"   "OAuth CF dari VM (URL dibuka di browser)"
  ROW "roc-tunnel oracle-create"  "tunnel VM: novnc.roadfx.biz.id → :6905 (+sshvm→:22)"
  ROW "roc-tunnel oracle-up"      "systemd enable+start cloudflared di VM"
  ROW "roc-tunnel oracle-status"  "status cloudflared di VM"
}
show_ag(){ SEC "🧠 Antigravity IDE — antigravity.ai.studio"
  ROW "hermes antigravity status" "status node HP (pinned 2.3.0 ARM64)"
  ROW "hermes antigravity vnc"    "Xvfb+x11vnc headless :5905"
  ROW "menu 19-21"         "status · web UI HP · node VM noVNC"
  NOTE "web HP: http://localhost:5905 · tunnel: https://ag.roadfx.biz.id"
  NOTE "VM (pending): noVNC :6905 → https://novnc.roadfx.biz.id (via roc-tunnel oracle-*)"
}
show_ai(){ SEC "🤖 AI & Agent"
  ROW "roc-agent chat"     "chat AI interaktif"
  ROW "roc-agent ask <q>"  "pertanyaan cepat"
  ROW "roc-ai orchestrator" "autonomous orchestrator"
  ROW "roc-agent provider" "atur provider/key (GCP/Gemini dll)"
}
show_sys(){ SEC "⚙️  System & util"
  ROW "roc-menu / roc"     "menu utama (00-27)"
  ROW "roc-status"         "status container udocker"
  ROW "roc-update"         "git pull + reinstall commands"
  ROW "roc-remote"         "remote dev connect (codespaces/oracle/aiven)"
  ROW "bash setup.sh"      "(re)install semua wrapper"
}
show_docs(){ SEC "📚 Panduan (docs/)"
  ROW "docs/OCI-ANDROID-VM-ROFWIN.md" "setting cloud.oracle utk VM Android / Rofwin"
  ROW "docs/BUILD_RELEASE.md"         "build & rilis Rofwin APK"
  NOTE "buka: menu 27 → roc-help docs · atau baca langsung di repo ~/.roc-containers/docs"
}
show_label(){ SEC "🏷️  Label resmi ekosistem"
  ROW "webvirtcloud.ai.studio" "alias panel Oracle VM (hermes vm + panel)"
  ROW "antigravity.ai.studio"  "alias panel Antigravity IDE (HP + VM)"
  ROW "ag.roadfx.biz.id"       "Antigravity HP via Cloudflare Tunnel"
  ROW "novnc.roadfx.biz.id"    "noVNC VM via Tunnel (digabung Oracle)"
  NOTE "*.ai.studio adalah label panel, bukan DNS sungguhan (milik Google)."
}

topic="${1:-}"
BANNER
case "$topic" in
  vm) show_vm ;;
  tunnel) show_tunnel ;;
  ag|antigravity) show_ag ;;
  ai) show_ai ;;
  sys|system) show_sys ;;
  docs) show_docs ;;
  label) show_label ;;
  *)
    show_vm; show_tunnel; show_ag; show_ai; show_sys; show_docs; show_label
    printf "\n${D}filter: roc-help [vm|tunnel|ag|ai|sys|docs|label]${N}\n"
    ;;
esac
