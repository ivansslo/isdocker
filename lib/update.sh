#!/data/data/com.termux/files/usr/bin/bash
# ─────────────────────────────────────────────────────────────────
#  Created by: ivansslo (2026)
#  License: MIT
#  Repo: https://github.com/ivansslo/isdocker
# ─────────────────────────────────────────────────────────────────

source "$(dirname "${BASH_SOURCE[0]}")/source.env"

echo -e "\n${YELLOW}[*] Checking for updates...${RESET}"
cd "$(dirname "${BASH_SOURCE[0]}")/.." || exit

if git pull; then
    echo -e "${GREEN}[✓] Repository updated successfully!${RESET}"
else
    echo -e "${RED}[!] Update failed. Check your internet connection.${RESET}"
fi

sleep 2
