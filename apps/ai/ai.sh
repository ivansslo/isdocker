#!/data/data/com.termux/files/usr/bin/bash
# ─────────────────────────────────────────────────────────────────
#  Created by: ivansslo (2026)
#  License: MIT
#  Repo: https://github.com/ivansslo/roc-containers
# ─────────────────────────────────────────────────────────────────
#  roc-containers · RoadFX AI Stack (roc-ai)
#  ⭐ PRIMARY TOOL — AI service container + local update
#  Clone: ivansslo/roadfx-ai-stack
# ─────────────────────────────────────────────────────────────────

source "$(dirname "${BASH_SOURCE[0]}")/../../lib/source.env" 2>/dev/null || true

# Colors
: "${RED:=$'\033[0;31m'}"; : "${GREEN:=$'\033[0;32m'}"; : "${YELLOW:=$'\033[1;33m'}"
: "${CYAN:=$'\033[0;36m'}"; : "${BLUE:=$'\033[0;34m'}"; : "${MAGENTA:=$'\033[0;35m'}"
: "${BOLD:=$'\033[1m'}"; : "${DIM:=$'\033[2m'}"; : "${RESET:=$'\033[0m'}"

AI_DIR="$HOME/.roc-containers/apps/ai/roadfx-ai-stack"
AI_REPO="https://github.com/ivansslo/roadfx-ai-stack"
AI_DATA_DIR="$HOME/.roc-containers/data-roadfx-ai"

# ──────────────────────────────────────────────────────────────
#  Core Functions
# ──────────────────────────────────────────────────────────────

# Clone or update roadfx-ai-stack
ai_ensure() {
  if [ ! -d "$AI_DIR/.git" ]; then
    echo -e "${YELLOW}[*] Cloning RoadFX AI Stack...${RESET}"
    git clone --depth 1 "$AI_REPO" "$AI_DIR" 2>/dev/null
    if [ $? -ne 0 ]; then
      echo -e "${RED}[✗] Gagal clone repo. Cek koneksi internet.${RESET}"
      exit 1
    fi
    echo -e "${GREEN}[✓] RoadFX AI Stack berhasil di-clone${RESET}"
  else
    echo -e "${DIM}[*] Checking for updates...${RESET}"
    local old_hash=$(git -C "$AI_DIR" rev-parse HEAD 2>/dev/null)
    git -C "$AI_DIR" pull --ff-only 2>/dev/null || true
    local new_hash=$(git -C "$AI_DIR" rev-parse HEAD 2>/dev/null)
    if [ "$old_hash" != "$new_hash" ]; then
      echo -e "${GREEN}[✓] Updated to latest version${RESET}"
    fi
  fi
  mkdir -p "$AI_DATA_DIR"
}

# Auto-update check (silent, non-blocking)
ai_auto_update() {
  if [ -d "$AI_DIR/.git" ]; then
    local last_update="$AI_DATA_DIR/.last_update"
    local now=$(date +%s)
    local interval=3600  # 1 hour

    if [ -f "$last_update" ]; then
      local last=$(cat "$last_update" 2>/dev/null || echo 0)
      if [ $((now - last)) -lt "$interval" ]; then
        return 0  # Too soon, skip
      fi
    fi

    git -C "$AI_DIR" fetch --quiet 2>/dev/null || true
    local local_hash=$(git -C "$AI_DIR" rev-parse HEAD 2>/dev/null)
    local remote_hash=$(git -C "$AI_DIR" rev-parse @{u} 2>/dev/null)

    if [ -n "$remote_hash" ] && [ "$local_hash" != "$remote_hash" ]; then
      echo -e "${YELLOW}[*] Update available! Pulling latest...${RESET}"
      git -C "$AI_DIR" pull --ff-only 2>/dev/null || true
      echo -e "${GREEN}[✓] Updated${RESET}"
    fi
    echo "$now" > "$last_update"
  fi
}

# Install dependencies
ai_install() {
  ai_ensure

  echo -e "${YELLOW}[*] Setting up RoadFX AI Stack...${RESET}"

  # Python dependencies
  if [ -f "$AI_DIR/requirements.txt" ]; then
    echo -e "${YELLOW}[*] Installing Python dependencies...${RESET}"
    local py="python3"
    if [ -x "$HOME/.hermes/python3_venv/bin/pip" ]; then
      "$HOME/.hermes/python3_venv/bin/pip" install -r "$AI_DIR/requirements.txt" 2>/dev/null || true
    elif command -v pip &>/dev/null; then
      pip install -r "$AI_DIR/requirements.txt" 2>/dev/null || true
    else
      echo -e "${YELLOW}[!] pip not found. Install: pkg install python${RESET}"
    fi
  fi

  # Node.js dependencies
  if [ -f "$AI_DIR/package.json" ]; then
    echo -e "${YELLOW}[*] Installing npm dependencies...${RESET}"
    if command -v npm &>/dev/null; then
      cd "$AI_DIR" && npm install --silent 2>/dev/null || true
    else
      echo -e "${YELLOW}[!] npm not found. Install: pkg install nodejs${RESET}"
    fi
  fi

  # Docker Compose check
  if [ -f "$AI_DIR/docker-compose.yml" ] || [ -f "$AI_DIR/docker-compose.yaml" ]; then
    echo -e "${DIM}[*] Docker Compose file detected${RESET}"
  fi

  echo -e "${GREEN}[✓] RoadFX AI Stack setup selesai${RESET}"
}

# Run / start the AI stack
ai_run() {
  ai_ensure
  ai_auto_update

  echo -e "${YELLOW}[*] Starting RoadFX AI Stack...${RESET}"

  # Try different entry points
  if [ -f "$AI_DIR/docker-compose.yml" ] || [ -f "$AI_DIR/docker-compose.yaml" ]; then
    echo -e "${YELLOW}[*] Detected docker-compose. Starting services...${RESET}"
    cd "$AI_DIR"
    if command -v docker-compose &>/dev/null; then
      docker-compose up -d 2>/dev/null || docker compose up -d 2>/dev/null || {
        echo -e "${YELLOW}[!] Docker compose gagal. Coba manual: cd $AI_DIR && docker-compose up${RESET}"
      }
    elif command -v udocker &>/dev/null; then
      echo -e "${YELLOW}[!] udocker tidak mendukung docker-compose langsung.${RESET}"
      echo -e "    ${CYAN}roc-ai shell${RESET} lalu jalankan manual."
    else
      echo -e "${RED}[!] Docker/docker-compose tidak ditemukan${RESET}"
    fi
  elif [ -f "$AI_DIR/package.json" ] && grep -q '"start"' "$AI_DIR/package.json"; then
    cd "$AI_DIR" && npm start
  elif [ -f "$AI_DIR/app.py" ]; then
    local py="python3"
    [ -x "$HOME/.hermes/python3_venv/bin/python" ] && py="$HOME/.hermes/python3_venv/bin/python"
    cd "$AI_DIR" && exec "$py" app.py "$@"
  elif [ -f "$AI_DIR/main.py" ]; then
    local py="python3"
    [ -x "$HOME/.hermes/python3_venv/bin/python" ] && py="$HOME/.hermes/python3_venv/bin/python"
    cd "$AI_DIR" && exec "$py" main.py "$@"
  elif [ -f "$AI_DIR/run.sh" ]; then
    cd "$AI_DIR" && exec bash run.sh "$@"
  elif [ -f "$AI_DIR/start.sh" ]; then
    cd "$AI_DIR" && exec bash start.sh "$@"
  else
    echo -e "${YELLOW}[!] Tidak ada entry point otomatis. Buka shell manual:${RESET}"
    echo -e "  ${CYAN}roc-ai shell${RESET}"
  fi
}

# Status — check all services
ai_status() {
  echo -e "${CYAN}${BOLD}"
  echo " ╔══════════════════════════════════════════════════════╗"
  echo " ║  RoadFX AI Stack — Service Status                   ║"
  echo " ╚══════════════════════════════════════════════════════╝"
  echo -e "${RESET}"

  # Repo status
  if [ -d "$AI_DIR/.git" ]; then
    local version=$(git -C "$AI_DIR" describe --tags --always 2>/dev/null || git -C "$AI_DIR" rev-parse --short HEAD 2>/dev/null)
    local branch=$(git -C "$AI_DIR" rev-parse --abbrev-ref HEAD 2>/dev/null)
    local last_pull=$(git -C "$AI_DIR" log -1 --format="%ar" 2>/dev/null)
    echo -e "  ${BOLD}Repo:${RESET}    ${GREEN}✓ installed${RESET}  ${DIM}($branch @ $version, $last_pull)${RESET}"
  else
    echo -e "  ${BOLD}Repo:${RESET}    ${RED}✗ not cloned${RESET}"
  fi

  # Python
  if command -v python3 &>/dev/null; then
    local pyver=$(python3 --version 2>/dev/null)
    echo -e "  ${BOLD}Python:${RESET}  ${GREEN}✓ $pyver${RESET}"
  else
    echo -e "  ${BOLD}Python:${RESET}  ${RED}✗ not installed${RESET}"
  fi

  # Node.js
  if command -v node &>/dev/null; then
    local nodever=$(node --version 2>/dev/null)
    echo -e "  ${BOLD}Node.js:${RESET} ${GREEN}✓ $nodever${RESET}"
  else
    echo -e "  ${BOLD}Node.js:${RESET} ${YELLOW}— not installed${RESET}"
  fi

  # Docker / udocker
  if command -v docker &>/dev/null; then
    echo -e "  ${BOLD}Docker:${RESET}  ${GREEN}✓ $(docker --version 2>/dev/null)${RESET}"
  elif command -v udocker &>/dev/null; then
    echo -e "  ${BOLD}udocker:${RESET}  ${GREEN}✓ available${RESET}"
  else
    echo -e "  ${BOLD}Docker:${RESET}  ${YELLOW}— not available${RESET}"
  fi

  # Running containers
  local containers=""
  if command -v udocker &>/dev/null; then
    containers=$(udocker ps 2>/dev/null | tail -n +2)
  fi
  if [ -n "$containers" ]; then
    echo -e "\n  ${BOLD}Running Containers:${RESET}"
    echo "$containers" | while read -r line; do
      echo -e "  ${GREEN}●${RESET} $line"
    done
  else
    echo -e "\n  ${DIM}No running containers${RESET}"
  fi

  # API Keys check
  echo -e "\n  ${BOLD}API Keys:${RESET}"
  local keys_found=0
  [ -f "$HOME/.hermes_keys" ] && source "$HOME/.hermes_keys" 2>/dev/null
  if [ -f "$HOME/.hermes/.keys" ]; then
    while IFS='=' read -r key val; do
      [[ "$key" =~ ^#.*$ || -z "$key" ]] && continue
      val="${val%\"}" ; val="${val#\"}" ; val="${val%\'}" ; val="${val#\'}"
      [ -z "${!key:-}" ] && export "$key=$val"
    done < "$HOME/.hermes/.keys"
  fi
  for k in GROQ_KEY GEMINI_API_KEY OR_KEY OPENAI_KEY TOKEN; do
    if [ -n "${!k:-}" ]; then
      echo -e "  ${GREEN}✓${RESET} $k ${DIM}(${!k:0:8}...)${RESET}"
      keys_found=$((keys_found + 1))
    else
      echo -e "  ${RED}✗${RESET} $k ${DIM}(not set)${RESET}"
    fi
  done

  if [ "$keys_found" -eq 0 ]; then
    echo -e "\n  ${YELLOW}[!] Belum ada API keys. Jalankan:${RESET} ${CYAN}roc-agent setup${RESET}"
  fi
}

# Docs
ai_docs() {
  ai_ensure
  if [ -f "$AI_DIR/README.md" ]; then
    cat "$AI_DIR/README.md"
  else
    echo -e "${YELLOW}[!] README.md tidak ditemukan${RESET}"
  fi
}

# List
ai_list() {
  ai_ensure
  echo -e "${BOLD}RoadFX AI Stack — Repo Contents:${RESET}\n"
  ls -1 "$AI_DIR/" | head -40
  echo ""
  echo -e "${DIM}Path: $AI_DIR${RESET}"
}

# Shell
ai_shell() {
  ai_ensure
  echo -e "${DIM}RoadFX AI Stack dir: $AI_DIR${RESET}"
  cd "$AI_DIR" && exec bash
}

# Update (force)
ai_update() {
  if [ ! -d "$AI_DIR/.git" ]; then
    ai_ensure
    return
  fi
  echo -e "${YELLOW}[*] Force updating RoadFX AI Stack...${RESET}"
  git -C "$AI_DIR" fetch --all 2>/dev/null || true
  git -C "$AI_DIR" pull --ff-only 2>/dev/null || true
  echo -e "${GREEN}[✓] Updated to latest${RESET}"

  # Re-install deps if needed
  if [ -f "$AI_DIR/requirements.txt" ]; then
    echo -e "${DIM}[*] Re-checking Python deps...${RESET}"
    if [ -x "$HOME/.hermes/python3_venv/bin/pip" ]; then
      "$HOME/.hermes/python3_venv/bin/pip" install -r "$AI_DIR/requirements.txt" --quiet 2>/dev/null || true
    fi
  fi
  if [ -f "$AI_DIR/package.json" ]; then
    echo -e "${DIM}[*] Re-checking npm deps...${RESET}"
    cd "$AI_DIR" && npm install --silent 2>/dev/null || true
  fi
}

# ──────────────────────────────────────────────────────────────
#  Main
# ──────────────────────────────────────────────────────────────
ai_main() {
  local cmd="${1:-}"

  if [ -z "$cmd" ]; then
    echo -e "${CYAN}${BOLD}"
    echo " ╔══════════════════════════════════════════════════════╗"
    echo " ║  ⭐ RoadFX AI Stack — roc-ai                       ║"
    echo " ║  ivansslo/roadfx-ai-stack                           ║"
    echo " ╚══════════════════════════════════════════════════════╝"
    echo -e "${RESET}"
    echo -e "  ${BOLD}Main AI service container — always updated${RESET}\n"
    echo -e " ${BOLD}Usage:${RESET}"
    echo -e "  ${CYAN}roc-ai install${RESET}   Clone & install dependencies"
    echo -e "  ${CYAN}roc-ai run${RESET}       Start AI stack services"
    echo -e "  ${CYAN}roc-ai status${RESET}    Check all services & keys status"
    echo -e "  ${CYAN}roc-ai docs${RESET}      View README"
    echo -e "  ${CYAN}roc-ai list${RESET}      List repo contents"
    echo -e "  ${CYAN}roc-ai shell${RESET}     Open shell in repo dir"
    echo -e "  ${CYAN}roc-ai update${RESET}    Force update to latest"
    echo ""
    echo -e " ${DIM}Repo: ivansslo/roadfx-ai-stack${RESET}"
    echo -e " ${DIM}Path: $AI_DIR${RESET}"
    return 0
  fi

  case "$cmd" in
    install|setup|i)
      ai_install
      ;;
    run|start|serve|s)
      shift
      ai_run "$@"
      ;;
    status|st|ps)
      ai_status
      ;;
    docs|readme|help|h)
      ai_docs
      ;;
    list|ls)
      ai_list
      ;;
    shell|sh)
      ai_shell
      ;;
    update|up|pull)
      ai_update
      ;;
    clone)
      ai_ensure
      ;;
    *)
      echo -e "${RED}Unknown command: $cmd${RESET}"
      echo -e "Run ${CYAN}roc-ai${RESET} for usage"
      ;;
  esac
}

ai_main "$@"
