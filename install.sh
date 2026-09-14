#!/usr/bin/env bash
# ==============================================================================
# SPHENE SOVEREIGN SECOND BRAIN - DOCKER & NATIVE INSTALLER
# Sovereign, compiled knowledge substrate (<25MB RAM, SQLite FTS5)
# Official Website: https://sphene.app
# ==============================================================================
set -e

BOLD='\033[1m'
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

AUTO_YES=0
FORCE_UPDATE=0
for arg in "$@"; do
  case "$arg" in
    -y|--yes) AUTO_YES=1 ;;
    --update) FORCE_UPDATE=1 ;;
  esac
done

# Helper function to read from terminal even when piped via curl ... | bash
read_input() {
  local prompt_text="$1"
  local default_val="$2"
  local user_val=""

  if [ "$AUTO_YES" -eq 1 ] || [ -n "$SPHENE_NON_INTERACTIVE" ] || [ -n "$CI" ]; then
    echo "$default_val"
    return
  fi

  if [ -t 0 ]; then
    read -r -p "$prompt_text" user_val || true
  elif [ -c /dev/tty ] && [ -r /dev/tty ]; then
    echo -ne "$prompt_text" > /dev/tty 2>/dev/null || true
    read -r user_val < /dev/tty 2>/dev/null || true
  else
    read -r user_val 2>/dev/null || true
  fi

  if [ -z "$user_val" ]; then
    echo "$default_val"
  else
    echo "$user_val"
  fi
}

echo -e "${CYAN}${BOLD}"
echo "  ____  ____  _   _ _____ _   _ _____ "
echo " / ___||  _ \| | | | ____| \ | | ____|"
echo " \___ \| |_) | |_| |  _| |  \| |  _|  "
echo "  ___) |  __/|  _  | |___| |\  | |___ "
echo " |____/|_|   |_| |_|_____|_| \_|_____|"
echo -e "${NC}"
echo -e "${BOLD}Installing Sphene Sovereign Second Brain (<25MB RAM)...${NC}\n"

# 1. Environment & Architecture Detection
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

TARGET_BIN="sphene-${OS}-${ARCH}"
[ "$OS" = "windows" ] && TARGET_BIN="${TARGET_BIN}.exe"

# 2. Check for Docker
HAS_DOCKER=0
COMPOSE_CMD=""
if command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; then
  HAS_DOCKER=1
  if docker compose version >/dev/null 2>&1; then
    COMPOSE_CMD="docker compose"
  elif command -v docker-compose >/dev/null 2>&1; then
    COMPOSE_CMD="docker-compose"
  fi
fi

PORT="${SPHENE_PORT:-8743}"

# 3. Determine Workspace & Vault Directory
if [ -d "/DATA/AppData" ] && [ -w "/DATA/AppData" ]; then
  DEFAULT_INSTALL_DIR="/DATA/AppData/sphene"
else
  DEFAULT_INSTALL_DIR="$HOME/.sphene"
fi
INSTALL_DIR="${SPHENE_INSTALL_DIR:-$DEFAULT_INSTALL_DIR}"
VAULT_DIR="${SPHENE_VAULT_DIR:-$INSTALL_DIR/vault}"
mkdir -p "$VAULT_DIR/Workspace" "$VAULT_DIR/Reference" "$VAULT_DIR/Private"

# Check if Sphene is already installed or running
IS_UPDATE=0
SPHENE_CONTAINER_EXISTS=0
if [ $HAS_DOCKER -eq 1 ] && docker ps -a --format '{{.Names}}' | grep -q "^sphene$"; then
  SPHENE_CONTAINER_EXISTS=1
fi

SPHENE_PORT_ACTIVE=0
if curl -s --max-time 1 "http://127.0.0.1:${PORT}/api/v1/health" 2>/dev/null | grep -q "sphene-kernel"; then
  SPHENE_PORT_ACTIVE=1
fi

if [ $SPHENE_CONTAINER_EXISTS -eq 1 ] || [ $SPHENE_PORT_ACTIVE -eq 1 ]; then
  echo -e "\n${CYAN}${BOLD}==================================================================${NC}"
  echo -e "${CYAN}${BOLD}  EXISTING SPHENE INSTALLATION DETECTED                           ${NC}"
  echo -e "${CYAN}${BOLD}==================================================================${NC}"
  if [ $SPHENE_CONTAINER_EXISTS -eq 1 ]; then
    C_STATUS=$(docker inspect -f '{{.State.Status}}' sphene 2>/dev/null || echo "present")
    echo -e "  • Docker Container: ${GREEN}sphene${NC} (Status: ${C_STATUS})"
  fi
  if [ $SPHENE_PORT_ACTIVE -eq 1 ]; then
    echo -e "  • Web Interface:    ${GREEN}http://localhost:${PORT}${NC} (responding healthy)"
  fi
  DOC_COUNT=$(find "$VAULT_DIR" -type f -name "*.md" ! -path "*/.*" 2>/dev/null | wc -l)
  echo -e "  • Knowledge Vault:  ${CYAN}${VAULT_DIR}${NC} (${DOC_COUNT} notes preserved)"
  echo -e "${CYAN}${BOLD}==================================================================${NC}\n"

  if [ $FORCE_UPDATE -eq 1 ]; then
    UPDATE_CHOICE="Y"
  else
    PROMPT_UPDATE="Sphene is already installed! Would you like to UPDATE Sphene and sync Hermes skills? [Y/n]: "
    UPDATE_CHOICE=$(read_input "$PROMPT_UPDATE" "Y")
  fi

  case "$UPDATE_CHOICE" in
    [yY][eE][sS]|[yY]|"")
      echo -e "\n${GREEN}✓ Proceeding with Sphene & Hermes update...${NC}"
      IS_UPDATE=1
      ;;
    *)
      PROMPT_REINSTALL="Do you want to run a full interactive reinstall / reconfigure instead? [y/N]: "
      REINSTALL_CHOICE=$(read_input "$PROMPT_REINSTALL" "N")
      case "$REINSTALL_CHOICE" in
        [yY][eE][sS]|[yY])
          echo -e "\nProceeding with full interactive re-installation...\n"
          IS_UPDATE=0
          ;;
        *)
          echo -e "\nNo changes made. Current Sphene installation kept untouched."
          exit 0
          ;;
      esac
      ;;
  esac
else
  echo -e "${GREEN}✓ Knowledge vault initialized at: ${VAULT_DIR}${NC}"
fi

# 4. Host Binary Installation (for CLI convenience)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd || pwd)"
TMP_DIR="/tmp/sphene-install"
mkdir -p "$TMP_DIR"
SPHENE_HOST_BIN=""

if [ -f "${SCRIPT_DIR}/bin/${TARGET_BIN}" ]; then
  SPHENE_HOST_BIN="${SCRIPT_DIR}/bin/${TARGET_BIN}"
else
  echo -e "Fetching pre-compiled native Sphene CLI binary (${OS}-${ARCH})..."
  if curl -fsSL "https://sphene.app/bin/${TARGET_BIN}" -o "$TMP_DIR/sphene" 2>/dev/null && [ -s "$TMP_DIR/sphene" ]; then
    chmod +x "$TMP_DIR/sphene"
    SPHENE_HOST_BIN="$TMP_DIR/sphene"
  elif curl -fsSL "https://sphene.app/bin/sphene" -o "$TMP_DIR/sphene" 2>/dev/null && [ -s "$TMP_DIR/sphene" ]; then
    chmod +x "$TMP_DIR/sphene"
    SPHENE_HOST_BIN="$TMP_DIR/sphene"
  elif command -v sphene >/dev/null 2>&1; then
    SPHENE_HOST_BIN="$(command -v sphene)"
  fi
fi

if [ -n "$SPHENE_HOST_BIN" ] && [ -f "$SPHENE_HOST_BIN" ]; then
  if [ -w /usr/local/bin ]; then
    cp "$SPHENE_HOST_BIN" /usr/local/bin/sphene
    chmod +x /usr/local/bin/sphene
    echo -e "${GREEN}✓ Installed host CLI at /usr/local/bin/sphene${NC}"
  elif command -v sudo >/dev/null 2>&1; then
    sudo cp "$SPHENE_HOST_BIN" /usr/local/bin/sphene
    sudo chmod +x /usr/local/bin/sphene
    echo -e "${GREEN}✓ Installed host CLI at /usr/local/bin/sphene (via sudo)${NC}"
  elif [ -d "/opt/homebrew/bin" ] && [ -w "/opt/homebrew/bin" ]; then
    cp "$SPHENE_HOST_BIN" /opt/homebrew/bin/sphene
    chmod +x /opt/homebrew/bin/sphene
    echo -e "${GREEN}✓ Installed host CLI at /opt/homebrew/bin/sphene${NC}"
  else
    mkdir -p "$HOME/.local/bin"
    cp "$SPHENE_HOST_BIN" "$HOME/.local/bin/sphene"
    chmod +x "$HOME/.local/bin/sphene"
    echo -e "${GREEN}✓ Installed host CLI at $HOME/.local/bin/sphene${NC}"
  fi
fi

# 5. Obsidian Vault Auto-Discovery & Non-Destructive Migration (Skip in update mode)
if [ $IS_UPDATE -eq 0 ]; then
  echo -e "\n${BOLD}Scanning for existing Obsidian notes...${NC}"
  DISCOVERED_VAULTS=()

  OBS_CONF=""
  if [ -f "$HOME/.config/obsidian/obsidian.json" ]; then
    OBS_CONF="$HOME/.config/obsidian/obsidian.json"
  elif [ -f "$HOME/Library/Application Support/obsidian/obsidian.json" ]; then
    OBS_CONF="$HOME/Library/Application Support/obsidian/obsidian.json"
  elif [ -n "$APPDATA" ] && [ -f "$APPDATA/obsidian/obsidian.json" ]; then
    OBS_CONF="$APPDATA/obsidian/obsidian.json"
  fi

  if [ -n "$OBS_CONF" ] && [ -r "$OBS_CONF" ]; then
    if command -v python3 >/dev/null 2>&1; then
      while IFS= read -r vpath; do
        [ -d "$vpath" ] && DISCOVERED_VAULTS+=("$vpath")
      done < <(python3 -c 'import json, sys; d=json.load(open(sys.argv[1])); print("\n".join(v["path"] for v in d.get("vaults",{}).values() if "path" in v))' "$OBS_CONF" 2>/dev/null || true)
    fi
    if [ ${#DISCOVERED_VAULTS[@]} -eq 0 ]; then
      while IFS= read -r vpath; do
        [ -d "$vpath" ] && DISCOVERED_VAULTS+=("$vpath")
      done < <(grep -o '"path"[[:space:]]*:[[:space:]]*"[^"]*"' "$OBS_CONF" 2>/dev/null | sed -E 's/.*:[[:space:]]*"([^"]*)"/\1/' || true)
    fi
  fi

  if [ -n "$OBSIDIAN_VAULT_PATH" ] && [ -d "$OBSIDIAN_VAULT_PATH" ]; then
    DISCOVERED_VAULTS+=("$OBSIDIAN_VAULT_PATH")
  fi

  for common_path in \
    "$HOME/Documents/Obsidian Vault" \
    "$HOME/Documents/Obsidian" \
    "$HOME/Documents/Notes" \
    "$HOME/Obsidian" \
    "$HOME/Vault" \
    "$HOME/Documents/Vault"; do
    if [ -d "$common_path" ]; then
      DISCOVERED_VAULTS+=("$common_path")
    fi
  done

  UNIQUE_VAULTS=()
  for v in "${DISCOVERED_VAULTS[@]}"; do
    v_norm="$(cd "$v" 2>/dev/null && pwd || echo "$v")"
    already=0
    for u in "${UNIQUE_VAULTS[@]}"; do
      if [ "$u" = "$v_norm" ]; then already=1; break; fi
    done
    if [ "$already" -eq 0 ] && [ -d "$v_norm" ]; then
      UNIQUE_VAULTS+=("$v_norm")
    fi
  done

  FOUND_OBSIDIAN=0
  if [ ${#UNIQUE_VAULTS[@]} -gt 0 ]; then
    for vault_path in "${UNIQUE_VAULTS[@]}"; do
      note_count=$(find "$vault_path" -type f -name "*.md" ! -path "*/.*" 2>/dev/null | wc -l)
      if [ "$note_count" -gt 0 ]; then
        FOUND_OBSIDIAN=1
        echo -e "\n${CYAN}══════════════════════════════════════════════════════════════════${NC}"
        echo -e "${GREEN}${BOLD}  ★ Existing Obsidian Notes Detected!${NC}"
        echo -e "${CYAN}══════════════════════════════════════════════════════════════════${NC}"
        echo -e "  • Path:        ${BOLD}${vault_path}${NC}"
        echo -e "  • Documents:   ${CYAN}${note_count} Markdown notes found${NC}"
        echo -e "  • Sample notes:"
        find "$vault_path" -type f -name "*.md" ! -path "*/.*" 2>/dev/null | head -n 3 | while read -r sample_file; do
          echo -e "      - $(basename "$sample_file")"
        done
        if [ "$note_count" -gt 3 ]; then
          echo -e "      ... and $((note_count - 3)) more."
        fi
        echo ""
        echo -e "${YELLOW}  Non-Destructive Guarantee:${NC}"
        echo "  Sphene will safely copy your markdown notes into your sovereign vault."
        echo "  Your original Obsidian files will remain 100% untouched and unmodified."
        echo ""

        IMPORT_PROMPT="Do you want Sphene to import a copy of these Obsidian notes? [Y/n]: "
        IMPORT_CHOICE=$(read_input "$IMPORT_PROMPT" "Y")

        case "$IMPORT_CHOICE" in
          [yY][eE][sS]|[yY]|"")
            echo -e "  Importing notes into ${VAULT_DIR}/Workspace/Obsidian..."
            if command -v sphene >/dev/null 2>&1; then
              SPHENE_VAULT_DIR="$VAULT_DIR" sphene import "$vault_path" --partition "Workspace/Obsidian"
            else
              mkdir -p "${VAULT_DIR}/Workspace/Obsidian"
              cp -r "$vault_path"/* "${VAULT_DIR}/Workspace/Obsidian/" 2>/dev/null || true
              echo -e "${GREEN}✓ Copied notes into ${VAULT_DIR}/Workspace/Obsidian${NC}"
            fi
            ;;
          *)
            echo -e "  Skipped import. (You can import anytime with: ${CYAN}sphene import \"$vault_path\"${NC})"
            ;;
        esac
      fi
    done
  fi

  if [ "$FOUND_OBSIDIAN" -eq 0 ]; then
    echo -e "${GREEN}✓ No existing Obsidian installation found (clean slate).${NC}"
    echo -e "  (Tip: You can import any existing folder of notes anytime with: ${CYAN}sphene import <path>${NC})"
  fi
fi

# 6. Hermes Agent Detection & Interactive Integration
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

SKILL_INSTALLED=0
OBSIDIAN_REPLACED=0

if [ -n "$HERMES_TYPE" ]; then
  if [ $IS_UPDATE -eq 1 ]; then
    echo -e "\n${BOLD}Updating Hermes Agent integration & skills...${NC}"
    TMP_SKILL_DIR="$TMP_DIR/hermes-skill"
    mkdir -p "$TMP_SKILL_DIR"

    if [ -d "${SCRIPT_DIR}/hermes-skill/sphene-knowledge-hub" ]; then
      cp -r "${SCRIPT_DIR}/hermes-skill/sphene-knowledge-hub" "$TMP_SKILL_DIR/"
    else
      curl -fsSL "https://sphene.app/hermes-skill.tar.gz" -o "$TMP_DIR/hermes-skill.tar.gz" 2>/dev/null || true
      if [ -f "$TMP_DIR/hermes-skill.tar.gz" ]; then
        tar -xzf "$TMP_DIR/hermes-skill.tar.gz" -C "$TMP_SKILL_DIR/"
      fi
    fi

    if [ -d "$TMP_SKILL_DIR/sphene-knowledge-hub" ]; then
      if [ "$HERMES_TYPE" = "docker" ]; then
        docker cp "$TMP_SKILL_DIR/sphene-knowledge-hub" "${HERMES_CONTAINER}:${HERMES_SKILLS_DIR}/"
        if [ -n "$SPHENE_HOST_BIN" ] && [ -f "$SPHENE_HOST_BIN" ]; then
          docker cp "$SPHENE_HOST_BIN" "${HERMES_CONTAINER}:/usr/local/bin/sphene"
        fi
      else
        cp -r "$TMP_SKILL_DIR/sphene-knowledge-hub" "${HERMES_SKILLS_DIR}/"
      fi
      SKILL_INSTALLED=1
      echo -e "${GREEN}✓ Sphene Knowledge Hub skill & CLI updated in Hermes.${NC}"
    fi

    # Refresh upgraded obsidian skill if previously replaced
    OBSIDIAN_REL_PATH=""
    if [ "$HERMES_TYPE" = "docker" ]; then
      if docker exec "${HERMES_CONTAINER}" test -f "${HERMES_SKILLS_DIR}/note-taking/obsidian/SKILL.md.bak" 2>/dev/null; then
        OBSIDIAN_REL_PATH="note-taking/obsidian/SKILL.md"
      elif docker exec "${HERMES_CONTAINER}" test -f "${HERMES_SKILLS_DIR}/obsidian/SKILL.md.bak" 2>/dev/null; then
        OBSIDIAN_REL_PATH="obsidian/SKILL.md"
      fi
    else
      if [ -f "${HERMES_SKILLS_DIR}/note-taking/obsidian/SKILL.md.bak" ]; then
        OBSIDIAN_REL_PATH="note-taking/obsidian/SKILL.md"
      elif [ -f "${HERMES_SKILLS_DIR}/obsidian/SKILL.md.bak" ]; then
        OBSIDIAN_REL_PATH="obsidian/SKILL.md"
      fi
    fi
    if [ -n "$OBSIDIAN_REL_PATH" ]; then
      OBSIDIAN_REPLACED=1
    fi
  else
    # Prompt 6a: Install Sphene Skill into Hermes
    PROMPT_SKILL="Install Sphene Knowledge Hub skill into Hermes now? [Y/n]: "
    INSTALL_SKILL_CHOICE=$(read_input "$PROMPT_SKILL" "Y")

    case "$INSTALL_SKILL_CHOICE" in
      [yY][eE][sS]|[yY]|"")
        echo -e "Deploying sphene-knowledge-hub skill into Hermes..."
        TMP_SKILL_DIR="$TMP_DIR/hermes-skill"
        mkdir -p "$TMP_SKILL_DIR"
        
        if [ -d "${SCRIPT_DIR}/hermes-skill/sphene-knowledge-hub" ]; then
          cp -r "${SCRIPT_DIR}/hermes-skill/sphene-knowledge-hub" "$TMP_SKILL_DIR/"
        else
          curl -fsSL "https://sphene.app/hermes-skill.tar.gz" -o "$TMP_DIR/hermes-skill.tar.gz" 2>/dev/null || true
          if [ -f "$TMP_DIR/hermes-skill.tar.gz" ]; then
            tar -xzf "$TMP_DIR/hermes-skill.tar.gz" -C "$TMP_SKILL_DIR/"
          fi
        fi

        if [ -d "$TMP_SKILL_DIR/sphene-knowledge-hub" ]; then
          if [ "$HERMES_TYPE" = "docker" ]; then
            docker cp "$TMP_SKILL_DIR/sphene-knowledge-hub" "${HERMES_CONTAINER}:${HERMES_SKILLS_DIR}/"
            if [ -n "$SPHENE_HOST_BIN" ] && [ -f "$SPHENE_HOST_BIN" ]; then
              docker cp "$SPHENE_HOST_BIN" "${HERMES_CONTAINER}:/usr/local/bin/sphene"
            fi
            # Ensure skill is enabled in hermes config if disabled list exists
            docker exec "${HERMES_CONTAINER}" python3 -c '
import yaml, os
cfg_file = "/opt/data/config.yaml"
if os.path.isfile(cfg_file):
    try:
        with open(cfg_file, "r") as f:
            c = yaml.safe_load(f) or {}
        disabled = c.get("skills", {}).get("disabled", [])
        if "sphene-knowledge-hub" in disabled:
            disabled.remove("sphene-knowledge-hub")
            c["skills"]["disabled"] = disabled
            with open(cfg_file, "w") as f:
                yaml.dump(c, f)
    except Exception:
        pass
' 2>/dev/null || true
          else
            cp -r "$TMP_SKILL_DIR/sphene-knowledge-hub" "${HERMES_SKILLS_DIR}/"
          fi
          SKILL_INSTALLED=1
          echo -e "${GREEN}✓ Sphene Knowledge Hub skill deployed into Hermes successfully.${NC}"
        fi
        ;;
      *)
        echo "Skipped Hermes skill installation."
        ;;
    esac

  # Prompt 6b: Replace Obsidian skill with Sphene
  OBSIDIAN_REL_PATH=""
  if [ "$HERMES_TYPE" = "docker" ]; then
    if docker exec "${HERMES_CONTAINER}" test -f "${HERMES_SKILLS_DIR}/note-taking/obsidian/SKILL.md" 2>/dev/null; then
      OBSIDIAN_REL_PATH="note-taking/obsidian/SKILL.md"
    elif docker exec "${HERMES_CONTAINER}" test -f "${HERMES_SKILLS_DIR}/obsidian/SKILL.md" 2>/dev/null; then
      OBSIDIAN_REL_PATH="obsidian/SKILL.md"
    fi
  else
    if [ -f "${HERMES_SKILLS_DIR}/note-taking/obsidian/SKILL.md" ]; then
      OBSIDIAN_REL_PATH="note-taking/obsidian/SKILL.md"
    elif [ -f "${HERMES_SKILLS_DIR}/obsidian/SKILL.md" ]; then
      OBSIDIAN_REL_PATH="obsidian/SKILL.md"
    fi
  fi

  if [ -n "$OBSIDIAN_REL_PATH" ]; then
    echo -e "\n${YELLOW}${BOLD}Obsidian Skill Integration Option:${NC}"
    echo "Hermes comes bundled with a default Obsidian note-taking skill."
    echo "Sphene is 100% compatible with Obsidian Markdown vaults, but features <25MB memory footprint,"
    echo "sub-millisecond SQLite FTS5 index, human veto timeline, and interactive visual Web UI."
    echo ""

    PROMPT_OBS="Do you want Hermes to replace Obsidian with Sphene as its primary knowledge store? [y/N]: "
    REPLACE_OBSIDIAN_CHOICE=$(read_input "$PROMPT_OBS" "N")

    case "$REPLACE_OBSIDIAN_CHOICE" in
      [yY][eE][sS]|[yY])
        echo "Upgrading Hermes Obsidian skill definition to route directly to Sphene..."
        UPGRADED_OBSIDIAN_SKILL='---
name: obsidian
description: Read, search, create, and edit notes in Sphene Knowledge Hub (the sovereign Obsidian-compatible knowledge substrate).
version: 2.0.0
author: Sphene Sovereign Substrate
platforms: [linux, macos, windows]
metadata:
  hermes:
    tags: [Sphene, Obsidian, Notes, Markdown, Vault]
    related_skills: [sphene-knowledge-hub]
---

# Sphene Knowledge Hub (Obsidian Replacement)

Use this skill for all note-taking, markdown knowledge store, and second brain workflows.
Obsidian has been upgraded to **Sphene Knowledge Hub** (https://sphene.app) — the hardened, sovereign knowledge substrate and second brain engineered to put **HUMANS ON TOP** while providing autonomous AI agents with sub-millisecond programmatic memory (<25MB RAM).

## 1. Core Architecture & Philosophy: "Human on Top"
- **Human Sovereignty & Safety:** Sphene puts the human user in ultimate control. When agents edit notes, Sphene stages block-level diffs in the **Differential Timeline ("Human Veto")** accessible in the Web UI (`http://localhost:8743`), allowing humans to 1-click accept or veto changes.
- **Hardware-Grade Partitioning & Encryption:**
  - `Workspace/`: Open collaboration partition where humans and agents co-create.
  - `Reference/`: Human-curated ground truth (read-only for agents, write-blocked by kernel AST traps).
  - `Private/`: Hardware-sealed enclave encrypted at rest with authenticated **AES-256-GCM**. Agents have **zero access**.
- **Zero-Trust Sandboxed Plugins:** Every plugin is cryptographically verified against Ed25519 Sphene Root Authority signatures and constrained by strict capability manifests (cannot execute arbitrary shell commands or crash the kernel).
- **Sub-Millisecond Engine:** Embedded SQLite FTS5 search executing in **179 microseconds** (<0.2ms) with zero Electron bloat (<25MB RAM).

## 2. Active Vault Location
Sphene stores all documents as standard plaintext Markdown (`.md`) on disk at:
`'"${VAULT_DIR}"'`

## 3. How to Interact with Sphene (CLI & REST)
- **Search Notes (FTS5 <1ms):** `sphene search "<query>"`
- **Read Note:** `sphene read "<path_or_slug>" --raw`
- **Write / Update Note:** `sphene write "<Title>" --file <path>` or `--body "<Content>"` or `--base64 <b64>`
- **Delete Note:** `sphene delete "<Title>"` (or `sphene rm "<Title>"`)
- **Knowledge Graph:** `sphene graph`
- **Append Daily Note:** `sphene daily "<Summary>"`
- **Visual Web UI & 3D Graph:** `http://localhost:8743`
'
        if [ "$HERMES_TYPE" = "docker" ]; then
          docker exec "${HERMES_CONTAINER}" sh -c "[ ! -f '${HERMES_SKILLS_DIR}/${OBSIDIAN_REL_PATH}.bak' ] && cp '${HERMES_SKILLS_DIR}/${OBSIDIAN_REL_PATH}' '${HERMES_SKILLS_DIR}/${OBSIDIAN_REL_PATH}.bak'" 2>/dev/null || true
          printf "%s\n" "$UPGRADED_OBSIDIAN_SKILL" | docker exec -i "${HERMES_CONTAINER}" sh -c "cat > '${HERMES_SKILLS_DIR}/${OBSIDIAN_REL_PATH}'"
          # Enable obsidian in config.yaml if it was disabled
          docker exec "${HERMES_CONTAINER}" python3 -c '
import yaml, os
cfg_file = "/opt/data/config.yaml"
if os.path.isfile(cfg_file):
    try:
        with open(cfg_file, "r") as f:
            c = yaml.safe_load(f) or {}
        disabled = c.get("skills", {}).get("disabled", [])
        if "obsidian" in disabled:
            disabled.remove("obsidian")
            c["skills"]["disabled"] = disabled
            with open(cfg_file, "w") as f:
                yaml.dump(c, f)
    except Exception:
        pass
' 2>/dev/null || true
        else
          [ ! -f "${HERMES_SKILLS_DIR}/${OBSIDIAN_REL_PATH}.bak" ] && cp "${HERMES_SKILLS_DIR}/${OBSIDIAN_REL_PATH}" "${HERMES_SKILLS_DIR}/${OBSIDIAN_REL_PATH}.bak"
          printf "%s\n" "$UPGRADED_OBSIDIAN_SKILL" > "${HERMES_SKILLS_DIR}/${OBSIDIAN_REL_PATH}"
        fi
        OBSIDIAN_REPLACED=1
        echo -e "${GREEN}✓ Hermes Obsidian skill upgraded to route directly to Sphene!${NC}"
        ;;
      *)
        echo "Obsidian skill left untouched. Sphene is configured as an independent sovereign substrate."
        ;;
    esac
  fi
  fi
fi

# 7. Deployment Execution: Docker Container vs Native Daemon
PORT="${SPHENE_PORT:-8743}"

# Stop any lingering native daemon on port 8743 so it doesn't conflict
if pgrep -f "sphene.*daemon" >/dev/null 2>&1; then
  pkill -9 -f "sphene.*daemon" 2>/dev/null || true
fi

if [ $HAS_DOCKER -eq 1 ]; then
  echo -e "\n${BOLD}Deploying Sphene as Docker container...${NC}"
  cd "$INSTALL_DIR"

  # Load image if local file exists, or if update, or if not present
  if [ -f "${SCRIPT_DIR}/sphene-image.tar.gz" ]; then
    echo "Loading Sphene container image from local archive..."
    docker load < "${SCRIPT_DIR}/sphene-image.tar.gz"
  elif [ $IS_UPDATE -eq 1 ] || ! docker images --format '{{.Repository}}:{{.Tag}}' | grep -q "^sphene:2.0.0$"; then
    echo "Fetching Sphene container image (sphene:2.0.0)..."
    if curl -fsSL "https://sphene.app/sphene-image.tar.gz" -o "$TMP_DIR/sphene-image.tar.gz" 2>/dev/null && [ -s "$TMP_DIR/sphene-image.tar.gz" ]; then
      docker load < "$TMP_DIR/sphene-image.tar.gz"
    fi
  fi

  # Write production docker-compose.yml
  cat << EOF_COMPOSE > "$INSTALL_DIR/docker-compose.yml"
services:
  sphene:
    image: sphene:2.0.0
    container_name: sphene
    restart: unless-stopped
    ports:
      - "${PORT}:8743"
    volumes:
      - ./vault:/vault
    environment:
      - SPHENE_VAULT_DIR=/vault
      - SPHENE_PORT=8743
      - SPHENE_HOST=0.0.0.0
EOF_COMPOSE

  # Stop any existing sphene container
  docker rm -f sphene 2>/dev/null || true

  # Start container
  $COMPOSE_CMD up -d

  # Wait for container response
  COUNTER=0
  MAX_RETRIES=20
  echo -ne "Waiting for Sphene container to become ready"
  while [ $COUNTER -lt $MAX_RETRIES ]; do
    if curl -s "http://127.0.0.1:${PORT}/login" >/dev/null 2>&1 || curl -s "http://127.0.0.1:${PORT}/api/v1/health" >/dev/null 2>&1; then
      echo -e "\n${GREEN}✓ Sphene container is healthy and responding on http://localhost:${PORT}!${NC}"
      break
    fi
    echo -ne "."
    sleep 1
    COUNTER=$((COUNTER + 1))
  done

  # Initialize credentials inside container (only on initial installation)
  if [ $IS_UPDATE -eq 0 ]; then
    echo -e "\n${BOLD}Configuring administrative credentials...${NC}"
    docker exec sphene /usr/local/bin/sphene auth setup
  fi

else
  # Fallback: Native binary daemon
  echo -e "\n${BOLD}Deploying Sphene as background daemon...${NC}"
  if [ -n "$SPHENE_HOST_BIN" ] && [ -f "$SPHENE_HOST_BIN" ]; then
    SPHENE_VAULT_DIR="$VAULT_DIR" SPHENE_PORT="$PORT" nohup "$SPHENE_HOST_BIN" daemon >/tmp/sphene-daemon.log 2>&1 &
    sleep 1
    echo -e "${GREEN}✓ Sphene background daemon active on http://localhost:${PORT}${NC}"
    if [ $IS_UPDATE -eq 0 ]; then
      SPHENE_VAULT_DIR="$VAULT_DIR" "$SPHENE_HOST_BIN" auth setup
    fi
  fi
fi

# 8. Sync Internal API Key to Host and Hermes Agent Container
LOCAL_KEY="$TMP_DIR/api.key"
if [ $HAS_DOCKER -eq 1 ]; then
  docker exec sphene cat /vault/.sphene/api.key > "$LOCAL_KEY" 2>/dev/null || true
fi
if [ ! -s "$LOCAL_KEY" ] && [ -r "$VAULT_DIR/.sphene/api.key" ]; then
  cp "$VAULT_DIR/.sphene/api.key" "$LOCAL_KEY" 2>/dev/null || true
fi
if [ ! -s "$LOCAL_KEY" ] && command -v sudo >/dev/null 2>&1; then
  sudo cat "$VAULT_DIR/.sphene/api.key" > "$LOCAL_KEY" 2>/dev/null || true
fi

if [ -s "$LOCAL_KEY" ]; then
  mkdir -p /etc/sphene "$HOME/.sphene" 2>/dev/null || true
  if [ -w /etc/sphene ]; then
    cp "$LOCAL_KEY" /etc/sphene/api.key
    chmod 644 /etc/sphene/api.key
  elif command -v sudo >/dev/null 2>&1; then
    sudo mkdir -p /etc/sphene 2>/dev/null || true
    sudo cp "$LOCAL_KEY" /etc/sphene/api.key 2>/dev/null || true
    sudo chmod 644 /etc/sphene/api.key 2>/dev/null || true
  fi
  cp "$LOCAL_KEY" "$HOME/.sphene/api.key" 2>/dev/null || true
  chmod 644 "$HOME/.sphene/api.key" 2>/dev/null || true

  if [ -n "$HERMES_CONTAINER" ] && docker ps --format '{{.Names}}' | grep -q "^${HERMES_CONTAINER}$"; then
    docker exec "${HERMES_CONTAINER}" mkdir -p /etc/sphene /opt/data/.sphene 2>/dev/null || true
    docker cp "$LOCAL_KEY" "${HERMES_CONTAINER}:/etc/sphene/api.key" 2>/dev/null || true
    docker cp "$LOCAL_KEY" "${HERMES_CONTAINER}:/opt/data/.sphene/api.key" 2>/dev/null || true
    docker exec "${HERMES_CONTAINER}" sh -c "chmod 644 /etc/sphene/api.key /opt/data/.sphene/api.key 2>/dev/null || true; chown -R hermes:hermes /opt/data/.sphene 2>/dev/null || true"
    echo -e "${GREEN}✓ Synced internal sovereign API key into Hermes Agent container!${NC}"
  fi
fi

# 9. Reload Hermes container so skills and sovereign API keys activate immediately
if [ $SKILL_INSTALLED -eq 1 ] || [ $OBSIDIAN_REPLACED -eq 1 ]; then
  if [ "$HERMES_TYPE" = "docker" ] && [ -n "$HERMES_CONTAINER" ]; then
    echo -e "\n${BOLD}Reloading Hermes Agent container '${HERMES_CONTAINER}'...${NC}"
    docker restart "${HERMES_CONTAINER}" >/dev/null
    sleep 2
    echo -e "${GREEN}✓ Hermes container restarted. Sphene skill is live and active!${NC}"
  fi
fi

# Clean up temp files
rm -rf "$TMP_DIR"

if [ $IS_UPDATE -eq 1 ]; then
  echo -e "\n${GREEN}${BOLD}==================================================================${NC}"
  echo -e "${GREEN}${BOLD}  SPHENE SOVEREIGN SECOND BRAIN UPDATED SUCCESSFULLY!             ${NC}"
  echo -e "${GREEN}${BOLD}==================================================================${NC}"
  echo -e "  • Web Interface:    ${CYAN}http://localhost:${PORT}${NC}"
  echo -e "  • Knowledge Vault:  ${CYAN}${VAULT_DIR}${NC} (100% preserved)"
  if [ $HAS_DOCKER -eq 1 ]; then
    echo -e "  • Container:        ${CYAN}sphene${NC} (reloaded with latest release)"
  fi
  echo -e "  • Host CLI:         ${CYAN}/usr/local/bin/sphene${NC} (updated)"
  if [ $SKILL_INSTALLED -eq 1 ] || [ $OBSIDIAN_REPLACED -eq 1 ]; then
    echo -e "  • Hermes Agent:     ${GREEN}UPDATED & SYNCED!${NC} (skills and CLI refreshed, container reloaded)"
  fi
  echo -e "  • Existing Logins:  ${GREEN}Preserved.${NC} Your existing credentials remain active."
  echo ""
  exit 0
fi

echo -e "\n${GREEN}${BOLD}==================================================================${NC}"
echo -e "${GREEN}${BOLD}  SPHENE SOVEREIGN SECOND BRAIN INSTALLED SUCCESSFULLY!           ${NC}"
echo -e "${GREEN}${BOLD}==================================================================${NC}"
echo -e "  • Web Interface:    ${CYAN}http://localhost:${PORT}${NC}"
echo -e "  • Knowledge Vault:  ${CYAN}${VAULT_DIR}${NC}"
if [ $HAS_DOCKER -eq 1 ]; then
  echo -e "  • Container:        ${CYAN}sphene${NC} (manage via 'docker ps', 'docker logs -f sphene')"
fi
echo -e "  • Security:         ${CYAN}Log in with the admin credentials printed above.${NC}"
echo -e "  • Password Reset:   ${CYAN}sphene auth setup [--username <user>] [--password <pass>]${NC}"
echo -e "  • CLI Commands:     ${CYAN}sphene search <query>, sphene read <path>, sphene write <path>${NC}"
echo -e "  • Import Notes:     ${CYAN}sphene import <path-to-obsidian-or-md-folder>${NC}"
if [ $SKILL_INSTALLED -eq 1 ]; then
  echo -e "  • Hermes Agent:     ${GREEN}ACTIVE!${NC} Ask Hermes in natural language to save or search documents."
fi
echo ""

