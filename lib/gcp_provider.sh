#!/data/data/com.termux/files/usr/bin/bash
# ─────────────────────────────────────────────────────────────────
#  Created by: ivansslo (2026)
#  License: MIT
#  Repo: https://github.com/ivansslo/roc-containers
# ─────────────────────────────────────────────────────────────────
#  roc-containers · Provider GCP — configure Google Cloud / Gemini creds
#  Stores values in ~/.hermes_keys (shared with crewai / antigravity)
# ─────────────────────────────────────────────────────────────────

source "$(dirname "${BASH_SOURCE[0]}")/source.env" 2>/dev/null

# Colors (fallback if not inherited from menu.sh)
: "${RED:=$'\033[0;31m'}"; : "${GREEN:=$'\033[0;32m'}"; : "${YELLOW:=$'\033[1;33m'}"
: "${CYAN:=$'\033[0;36m'}"; : "${BLUE:=$'\033[0;34m'}"; : "${BOLD:=$'\033[1m'}"
: "${DIM:=$'\033[2m'}"; : "${RESET:=$'\033[0m'}"

KEYS_FILE="$HOME/.hermes_keys"
touch "$KEYS_FILE"
chmod 600 "$KEYS_FILE" 2>/dev/null || true

# ── Helpers ──────────────────────────────────────────────────────
get_key(){ grep -E "^$1=" "$KEYS_FILE" 2>/dev/null | cut -d= -f2- ; }

set_key(){
  local k="$1" v="$2"
  # Remove existing line, then append (portable, no in-place sed quirks)
  grep -vE "^$k=" "$KEYS_FILE" 2>/dev/null > "$KEYS_FILE.tmp" || true
  echo "$k=$v" >> "$KEYS_FILE.tmp"
  mv "$KEYS_FILE.tmp" "$KEYS_FILE"
  chmod 600 "$KEYS_FILE" 2>/dev/null || true
}

mask(){
  local s="$1"
  local n=${#s}
  [ "$n" -le 8 ] && { [ -n "$s" ] && echo "********" || echo "(not set)"; return; }
  echo "${s:0:4}…${s: -4}"
}

show_status(){
  echo -e "\n  ${DIM}Current GCP provider config (${KEYS_FILE}):${RESET}"
  echo -e "    GEMINI_API_KEY : $(mask "$(get_key GEMINI_API_KEY)")"
  echo -e "    GCP_PROJECT    : $(get_key GCP_PROJECT)"
  echo -e "    GCP_LOCATION   : $(get_key GCP_LOCATION)"
  echo -e "    VERTEX (Vertex AI): $(get_key GCP_USE_VERTEX)"
}

# ── Menu ─────────────────────────────────────────────────────────
gcp_menu(){
  while true; do
    clear
    echo -e "${BLUE}${BOLD}  ╔══════════════════════════════════════════════════════╗"
    echo    "  ║             roc-containers · Provider: GCP                 ║"
    echo -e "  ╚══════════════════════════════════════════════════════╝${RESET}"
    echo -e "  ${DIM}Google Cloud / Gemini credentials for Antigravity & hermes${RESET}"

    show_status

    echo ""
    echo -e "  ${CYAN}[1] Set Gemini / Google AI API Key"
    echo -e "  [2] Set GCP Project ID"
    echo -e "  [3] Set GCP Location/Region (default us-central1)"
    echo -e "  [4] Toggle Vertex AI mode (project-based)"
    echo -e "  [5] Import Service Account JSON (path)"
    echo -e "  [6] Test key (Gemini API ping)"
    echo -e "  [7] Clear all GCP keys"
    echo -e "  [0] Back to Menu${RESET}"
    echo ""
    echo -en "  Select: "
    read -r c

    case "$c" in
      1)
        echo -en "\n  Enter Gemini/Google AI API Key (AIza...): "
        read -r v
        [ -n "$v" ] && { set_key GEMINI_API_KEY "$v"; set_key GOOGLE_API_KEY "$v"; echo -e "  ${GREEN}[✓] Saved.${RESET}"; }
        ;;
      2)
        echo -en "\n  Enter GCP Project ID: "
        read -r v
        [ -n "$v" ] && { set_key GCP_PROJECT "$v"; echo -e "  ${GREEN}[✓] Saved.${RESET}"; }
        ;;
      3)
        echo -en "\n  Enter Location/Region (e.g. us-central1): "
        read -r v
        [ -z "$v" ] && v="us-central1"
        set_key GCP_LOCATION "$v"; echo -e "  ${GREEN}[✓] Saved: $v${RESET}"
        ;;
      4)
        cur="$(get_key GCP_USE_VERTEX)"
        if [ "$cur" = "true" ]; then set_key GCP_USE_VERTEX "false"; else set_key GCP_USE_VERTEX "true"; fi
        echo -e "  ${GREEN}[✓] Vertex AI = $(get_key GCP_USE_VERTEX)${RESET}"
        ;;
      5)
        echo -en "\n  Path to service-account JSON: "
        read -r p
        if [ -f "$p" ]; then
          dest="$HOME/.roc-containers_gcp_sa.json"
          cp "$p" "$dest" && chmod 600 "$dest"
          set_key GOOGLE_APPLICATION_CREDENTIALS "$dest"
          # Try to auto-fill project from the JSON
          pj="$(grep -oE '"project_id"[^,]*' "$dest" | cut -d'"' -f4)"
          [ -n "$pj" ] && set_key GCP_PROJECT "$pj"
          echo -e "  ${GREEN}[✓] Imported → $dest${RESET}"
        else
          echo -e "  ${RED}[!] File not found.${RESET}"
        fi
        ;;
      6)
        key="$(get_key GEMINI_API_KEY)"
        if [ -z "$key" ]; then
          echo -e "  ${RED}[!] No key set (option 1 first).${RESET}"
        elif ! command -v curl >/dev/null 2>&1; then
          echo -e "  ${YELLOW}[!] curl not available to test.${RESET}"
        else
          echo -e "  ${YELLOW}[*] Pinging Generative Language API...${RESET}"
          code="$(curl -s -o /dev/null -w '%{http_code}' \
            "https://generativelanguage.googleapis.com/v1beta/models?key=$key")"
          if [ "$code" = "200" ]; then
            echo -e "  ${GREEN}[✓] Key OK (HTTP 200).${RESET}"
          else
            echo -e "  ${RED}[!] HTTP $code — key may be invalid or no network.${RESET}"
          fi
        fi
        ;;
      7)
        for k in GEMINI_API_KEY GOOGLE_API_KEY GCP_PROJECT GCP_LOCATION GCP_USE_VERTEX GOOGLE_APPLICATION_CREDENTIALS; do
          grep -vE "^$k=" "$KEYS_FILE" 2>/dev/null > "$KEYS_FILE.tmp" || true
          mv "$KEYS_FILE.tmp" "$KEYS_FILE"
        done
        rm -f "$HOME/.roc-containers_gcp_sa.json"
        echo -e "  ${GREEN}[✓] GCP keys cleared.${RESET}"
        ;;
      0|q|Q) return 0 ;;
      *) echo -e "  ${RED}Invalid.${RESET}" ;;
    esac
    echo -en "\n  ${DIM}Press Enter...${RESET}"; read -r
  done
}

gcp_menu
