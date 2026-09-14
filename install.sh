#!/usr/bin/env bash
# ==============================================================================
# SPHENE SOVEREIGN SECOND BRAIN - INSTALLER & SETUP
# Ultra-lightweight compiled knowledge substrate (<25MB RAM, SQLite FTS5)
# Official Website: https://sphene.app
# ==============================================================================
set -e

BOLD='\033[1m'
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${CYAN}${BOLD}"
echo "  ____  ____  _   _ _____ _   _ _____ "
echo " / ___||  _ \| | | | ____| \ | | ____|"
echo " \___ \| |_) | |_| |  _| |  \| |  _|  "
echo "  ___) |  __/|  _  | |___| |\  | |___ "
echo " |____/|_|   |_| |_|_____|_| \_|_____|"
echo -e "${NC}"
echo -e "${BOLD}Installing Sphene Sovereign Second Brain (<25MB RAM)...${NC}\n"

# 1. Build, locate, or fetch binary
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd || pwd)"
SPHENE_BIN=""

if [ -f "${SCRIPT_DIR}/bin/sphene" ]; then
  SPHENE_BIN="${SCRIPT_DIR}/bin/sphene"
elif [ -f "/Nas/Projects/sphene/bin/sphene" ]; then
  SPHENE_BIN="/Nas/Projects/sphene/bin/sphene"
elif command -v sphene >/dev/null 2>&1; then
  SPHENE_BIN="$(command -v sphene)"
elif [ -f "${SCRIPT_DIR}/cmd/sphene/main.go" ] && command -v go >/dev/null 2>&1; then
  echo "Building native Sphene binary from Go source..."
  (cd "$SCRIPT_DIR" && go build -o bin/sphene ./cmd/sphene)
  SPHENE_BIN="${SCRIPT_DIR}/bin/sphene"
else
  # Fetch pre-compiled native binary from Cloudflare Pages distribution
  OS_RAW="$(uname -s)"
  ARCH_RAW="$(uname -m)"

  case "$OS_RAW" in
    Darwin*) OS="darwin" ;;
    Linux*)  OS="linux" ;;
    MSYS*|MINGW*|CYGWIN*) OS="windows" ;;
    *)       OS="$(echo "$OS_RAW" | tr '[:upper:]' '[:lower:]')" ;;
  esac

  case "$ARCH_RAW" in
    x86_64|amd64)   ARCH="amd64" ;;
    arm64|aarch64)  ARCH="arm64" ;;
    armv7*|armhf)   ARCH="arm" ;;
    i386|i686)      ARCH="386" ;;
    *)              ARCH="$ARCH_RAW" ;;
  esac

  TARGET_FILE="sphene-${OS}-${ARCH}"
  if [ "$OS" = "windows" ]; then
    TARGET_FILE="${TARGET_FILE}.exe"
  fi

  DOWNLOAD_URL="https://sphene.app/bin/${TARGET_FILE}"
  TMP_DIR="/tmp/sphene-install"
  TMP_BIN="${TMP_DIR}/sphene"
  mkdir -p "$TMP_DIR"
  echo "Auto-detected system architecture: ${OS}-${ARCH}"
  echo "Fetching pre-compiled native Sphene binary from https://sphene.app..."
  if curl -fsSL "$DOWNLOAD_URL" -o "$TMP_BIN" 2>/dev/null && [ -s "$TMP_BIN" ]; then
    chmod +x "$TMP_BIN"
    SPHENE_BIN="$TMP_BIN"
  elif curl -fsSL "https://sphene.app/bin/sphene" -o "$TMP_BIN" 2>/dev/null && [ -s "$TMP_BIN" ]; then
    chmod +x "$TMP_BIN"
    SPHENE_BIN="$TMP_BIN"
  elif command -v go >/dev/null 2>&1; then
    echo "Compiling latest Sphene binary..."
    GOBIN="$TMP_DIR" go install github.com/sphene-org/sphene/cmd/sphene@latest || true
    if [ -f "$TMP_DIR/sphene" ]; then
      SPHENE_BIN="$TMP_DIR/sphene"
    fi
  fi
fi

if [ -z "$SPHENE_BIN" ] || [ ! -f "$SPHENE_BIN" ]; then
  echo -e "${RED}Error: Sphene binary could not be found or built automatically for ${OS}-${ARCH}.${NC}"
  echo -e "Please check network access or build directly with Go: go build ./cmd/sphene"
  exit 1
fi

# 2. Install binary globally across macOS, Linux, or WSL2
INSTALLED=0
if [ -d "/opt/homebrew/bin" ] && [ -w "/opt/homebrew/bin" ]; then
  cp "$SPHENE_BIN" /opt/homebrew/bin/sphene
  chmod +x /opt/homebrew/bin/sphene
  SPHENE_BIN="/opt/homebrew/bin/sphene"
  INSTALLED=1
  echo -e "${GREEN}✓ Installed /opt/homebrew/bin/sphene${NC}"
elif [ -d "/usr/local/bin" ] && [ -w "/usr/local/bin" ]; then
  cp "$SPHENE_BIN" /usr/local/bin/sphene
  chmod +x /usr/local/bin/sphene
  SPHENE_BIN="/usr/local/bin/sphene"
  INSTALLED=1
  echo -e "${GREEN}✓ Installed /usr/local/bin/sphene${NC}"
elif command -v sudo >/dev/null 2>&1; then
  TARGET_PATH="/usr/local/bin/sphene"
  if [ "$OS" = "darwin" ] && [ -d "/opt/homebrew/bin" ]; then
    TARGET_PATH="/opt/homebrew/bin/sphene"
  fi
  sudo mkdir -p "$(dirname "$TARGET_PATH")"
  sudo cp "$SPHENE_BIN" "$TARGET_PATH"
  sudo chmod +x "$TARGET_PATH"
  SPHENE_BIN="$TARGET_PATH"
  INSTALLED=1
  echo -e "${GREEN}✓ Installed ${TARGET_PATH} (via sudo)${NC}"
fi

if [ "$INSTALLED" -eq 0 ]; then
  USER_BIN="$HOME/.local/bin"
  mkdir -p "$USER_BIN"
  cp "$SPHENE_BIN" "$USER_BIN/sphene"
  chmod +x "$USER_BIN/sphene"
  SPHENE_BIN="$USER_BIN/sphene"
  echo -e "${GREEN}✓ Installed to ${SPHENE_BIN}${NC}"
  if ! echo "$PATH" | grep -q "$USER_BIN"; then
    echo -e "${YELLOW}Notice: Add 'export PATH=\"\$HOME/.local/bin:\$PATH\"' to your ~/.zshrc or ~/.bashrc${NC}"
  fi
fi

# 3. Vault layout
if [ -d "/DATA/AppData" ] && [ -w "/DATA/AppData" ]; then
  DEFAULT_VAULT="/DATA/AppData/sphene/vault"
else
  DEFAULT_VAULT="$HOME/.sphene/vault"
fi
VAULT_DIR="${SPHENE_VAULT_DIR:-$DEFAULT_VAULT}"
mkdir -p "${VAULT_DIR}/Workspace" "${VAULT_DIR}/Reference" "${VAULT_DIR}/Private"
echo -e "${GREEN}✓ Knowledge vault initialized at: ${VAULT_DIR}${NC}"

# 4. Hermes Agent Detection & Integration
echo -e "\n${BOLD}Scanning for Hermes Agent installations...${NC}"
HERMES_TYPE=""
HERMES_CONTAINER=""
HERMES_SKILLS_DIR=""

if command -v docker >/dev/null 2>&1 && docker ps --format '{{.Names}}' | grep -q "^hermes$"; then
  HERMES_TYPE="docker"
  HERMES_CONTAINER="hermes"
  HERMES_SKILLS_DIR="/opt/data/skills"
  echo -e "${GREEN}✓ Found running Hermes Agent container: '${HERMES_CONTAINER}'${NC}"
elif [ -d "$HOME/.hermes/skills" ]; then
  HERMES_TYPE="local"
  HERMES_SKILLS_DIR="$HOME/.hermes/skills"
  echo -e "${GREEN}✓ Found local Hermes installation: ${HERMES_SKILLS_DIR}${NC}"
elif [ -d "/DATA/AppData/hermes/skills" ]; then
  HERMES_TYPE="local"
  HERMES_SKILLS_DIR="/DATA/AppData/hermes/skills"
  echo -e "${GREEN}✓ Found local Hermes installation: ${HERMES_SKILLS_DIR}${NC}"
fi

if [ -n "$HERMES_TYPE" ]; then
  if [ "$HERMES_TYPE" = "docker" ]; then
    docker cp "$SPHENE_BIN" "${HERMES_CONTAINER}:/usr/local/bin/sphene"
    echo -e "${GREEN}✓ Synced sphene binary into container ${HERMES_CONTAINER}:/usr/local/bin/sphene${NC}"
    if [ -f "${VAULT_DIR}/.sphene/api.key" ]; then
      docker exec "${HERMES_CONTAINER}" mkdir -p /etc/sphene
      docker cp "${VAULT_DIR}/.sphene/api.key" "${HERMES_CONTAINER}:/etc/sphene/api.key"
      echo -e "${GREEN}✓ Synced internal API key into container ${HERMES_CONTAINER}:/etc/sphene/api.key${NC}"
    fi
  fi

  echo -e "\n${YELLOW}${BOLD}Obsidian Skill Integration Option:${NC}"
  echo "Hermes comes bundled with a default Obsidian note-taking skill."
  echo "Sphene is 100% compatible with Obsidian Markdown vaults, but features <25MB memory footprint,"
  echo "sub-millisecond SQLite FTS5 index, human veto timeline, and interactive visual Web UI."
  echo ""
  
  REPLACE_OBSIDIAN_CHOICE="N"
  if [ "$1" = "--replace-obsidian" ] || [ "$SPHENE_REPLACE_OBSIDIAN" = "1" ]; then
    REPLACE_OBSIDIAN_CHOICE="Y"
  elif [ -t 0 ]; then
    read -r -p "Do you want Hermes to replace Obsidian with Sphene as its primary knowledge store? [y/N]: " USER_RESP || true
    [ -n "$USER_RESP" ] && REPLACE_OBSIDIAN_CHOICE="$USER_RESP"
  fi

  case "$REPLACE_OBSIDIAN_CHOICE" in
    [yY][eE][sS]|[yY])
      echo "Upgrading Hermes Obsidian skill definition to route directly to Sphene..."
      "$SPHENE_BIN" hermes-setup --replace-obsidian
      ;;
    *)
      echo "Obsidian skill left untouched. Sphene operates as an independent sovereign substrate."
      ;;
  esac
fi

# 5. Initialize Administrative Credentials
echo -e "\n${BOLD}Configuring administrative credentials...${NC}"
SPHENE_VAULT_DIR="$VAULT_DIR" "$SPHENE_BIN" auth setup

# 6. Verify Daemon Status
echo -e "\n${BOLD}Verifying daemon status...${NC}"
PORT="${SPHENE_PORT:-8743}"
if curl -s "http://127.0.0.1:${PORT}/api/notes" >/dev/null 2>&1 || curl -s "http://127.0.0.1:${PORT}/login" >/dev/null 2>&1; then
  echo -e "${GREEN}✓ Sphene daemon is running and responding on http://localhost:${PORT}${NC}"
else
  echo -e "${YELLOW}Starting Sphene background daemon on port ${PORT}...${NC}"
  SPHENE_VAULT_DIR="$VAULT_DIR" SPHENE_PORT="$PORT" nohup "$SPHENE_BIN" daemon >/tmp/sphene-daemon.log 2>&1 &
  sleep 1
  if curl -s "http://127.0.0.1:${PORT}/login" >/dev/null 2>&1; then
    echo -e "${GREEN}✓ Sphene background daemon active on http://localhost:${PORT}${NC}"
  else
    echo -e "${YELLOW}Notice: Run 'sphene daemon' to start the local server anytime.${NC}"
  fi
fi

echo -e "\n${GREEN}${BOLD}==================================================================${NC}"
echo -e "${GREEN}${BOLD}  SPHENE SOVEREIGN SECOND BRAIN INSTALLED SUCCESSFULLY!           ${NC}"
echo -e "${GREEN}${BOLD}==================================================================${NC}"
echo -e "  • Web Interface:    ${CYAN}http://localhost:${PORT}${NC}"
echo -e "  • Knowledge Vault:  ${CYAN}${VAULT_DIR}${NC}"
echo -e "  • Security:         ${CYAN}Log in with the admin credentials printed above.${NC}"
echo -e "  • Password Reset:   ${CYAN}sphene auth setup [--username <user>] [--password <pass>]${NC}"
echo -e "  • CLI Commands:     ${CYAN}sphene search <query>, sphene read <path>, sphene write <path>${NC}"
echo -e "  • Extensions:       ${CYAN}sphene plugin list, sphene plugin install <id>${NC}"
echo -e "  • Hermes Setup:     ${CYAN}sphene hermes-setup [--replace-obsidian | --restore-obsidian]${NC}\n"
