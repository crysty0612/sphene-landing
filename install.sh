#!/usr/bin/env bash
# ==============================================================================
#  SPHENE KNOWLEDGE HUB - ONE-LINE BINARY INSTALLER
# ==============================================================================
set -e

SPHENE_VERSION="1.0.0"
DEFAULT_INSTALL_DIR="sphene"
DEFAULT_PORT="${SPHENE_PORT:-8743}"
MIRROR_BASE_URL="${SPHENE_MIRROR:-https://sphene.app}"

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
echo -e "${BOLD}SPHENE KNOWLEDGE SUBSTRATE - v${SPHENE_VERSION}${NC}"
echo -e "Deterministic, flat-file, sovereign encrypted knowledge engine for Humans & AI."
echo "------------------------------------------------------------------"

# 1. Dependency checks
echo -e "\n${BOLD}[1/4] Checking system prerequisites...${NC}"
for cmd in curl tar docker; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo -e "${RED}[ERROR] Required command '$cmd' is not installed.${NC}"
    exit 1
  fi
done

if ! docker info >/dev/null 2>&1; then
  echo -e "${RED}[ERROR] Docker daemon is not running or current user cannot access docker.${NC}"
  exit 1
fi

if docker compose version >/dev/null 2>&1; then
  COMPOSE_CMD="docker compose"
elif command -v docker-compose >/dev/null 2>&1; then
  COMPOSE_CMD="docker-compose"
else
  echo -e "${RED}[ERROR] Docker Compose is required but was not found.${NC}"
  exit 1
fi
echo -e "${GREEN}✓ System dependencies and Docker engine ready.${NC}"

# 2. Destination directory
INSTALL_DIR="${1:-$DEFAULT_INSTALL_DIR}"
echo -e "\n${BOLD}[2/4] Preparing installation workspace at: ${CYAN}${INSTALL_DIR}${NC}..."
mkdir -p "$INSTALL_DIR/vault"
cd "$INSTALL_DIR"

# 3. Download encrypted runtime image and skills
echo -e "\n${BOLD}[3/4] Fetching encrypted Sphene engine image...${NC}"
IMAGE_URL="${MIRROR_BASE_URL}/sphene-image.tar.gz"
RELEASE_URL="https://github.com/crysty0612/sphene-landing/releases/latest/download/sphene-image.tar.gz"
echo "Downloading engine from: $IMAGE_URL"

if ! curl -fSL --progress-bar "$IMAGE_URL" -o sphene-image.tar.gz 2>/dev/null; then
  echo "Mirror redirected or pending, downloading directly from release repository..."
  if ! curl -fSL --progress-bar "$RELEASE_URL" -o sphene-image.tar.gz; then
    echo -e "${RED}[ERROR] Could not download Sphene runtime image. Please check network connectivity.${NC}"
    exit 1
  fi
fi

echo "Loading encrypted Sphene engine into Docker..."
docker load < sphene-image.tar.gz
rm -f sphene-image.tar.gz
echo -e "${GREEN}✓ Sphene engine loaded into Docker successfully.${NC}"

# Download Hermes skill bundle
echo "Fetching Hermes Agent integration skill..."
SKILL_URL="${MIRROR_BASE_URL}/hermes-skill.tar.gz"
mkdir -p hermes-skill
if curl -fsSL "$SKILL_URL" -o hermes-skill.tar.gz 2>/dev/null; then
  tar -xzf hermes-skill.tar.gz -C hermes-skill/
  rm -f hermes-skill.tar.gz
  echo -e "${GREEN}✓ Hermes Agent skill ready.${NC}"
else
  curl -fsSL "https://github.com/crysty0612/sphene-landing/releases/latest/download/hermes-skill.tar.gz" -o hermes-skill.tar.gz 2>/dev/null || true
  if [ -f hermes-skill.tar.gz ]; then
    tar -xzf hermes-skill.tar.gz -C hermes-skill/
    rm -f hermes-skill.tar.gz
    echo -e "${GREEN}✓ Hermes Agent skill ready.${NC}"
  fi
fi

# Port conflict detection & resolution
is_port_in_use() {
  local port="$1"
  if (exec 3<>/dev/tcp/127.0.0.1/"$port") 2>/dev/null; then
    exec 3>&-
    exec 3<&-
    return 0
  fi
  if command -v ss >/dev/null 2>&1; then
    if ss -tulpn 2>/dev/null | grep -qE ":${port}\b"; then
      return 0
    fi
  elif command -v lsof >/dev/null 2>&1; then
    if lsof -iTCP:"$port" -sTCP:LISTEN -P -n >/dev/null 2>&1; then
      return 0
    fi
  fi
  if command -v python3 >/dev/null 2>&1; then
    if ! python3 -c "import socket; s = socket.socket(); s.bind(('0.0.0.0', int('$port'))); s.close()" >/dev/null 2>&1; then
      return 0
    fi
  fi
  return 1
}

find_next_free_port() {
  local p="${1:-8743}"
  while is_port_in_use "$p"; do
    p=$((p + 1))
  done
  echo "$p"
}

DESIRED_PORT="${SPHENE_PORT:-8743}"
TARGET_PORT="$DESIRED_PORT"

if is_port_in_use "$DESIRED_PORT"; then
  echo -e "\n${YELLOW}[PORT CONFLICT] Default port ${DESIRED_PORT} is currently occupied by another service.${NC}"
  SUGGESTED_PORT=$(find_next_free_port "$DESIRED_PORT")
  
  if [ -t 0 ]; then
    read -r -p "Specify an alternate host port for Sphene Knowledge Hub [default: ${SUGGESTED_PORT}]: " USER_PORT
    TARGET_PORT="${USER_PORT:-$SUGGESTED_PORT}"
  elif [ -t 1 ] && [ -c /dev/tty ]; then
    echo -ne "${CYAN}Specify an alternate host port for Sphene Knowledge Hub [default: ${SUGGESTED_PORT}]: ${NC}"
    if read -t 15 -r USER_PORT < /dev/tty 2>/dev/null; then
      TARGET_PORT="${USER_PORT:-$SUGGESTED_PORT}"
    else
      echo ""
      TARGET_PORT="$SUGGESTED_PORT"
    fi
  else
    echo -e "${YELLOW}Non-interactive installation detected. Automatically reassigning to free port: ${SUGGESTED_PORT}${NC}"
    TARGET_PORT="$SUGGESTED_PORT"
  fi
  echo -e "${GREEN}✓ Using port ${TARGET_PORT} for Sphene Hub.${NC}"
fi

# Generate clean deployment docker-compose.yml
cat << EOF_COMPOSE > docker-compose.yml
services:
  sphene:
    image: sphene:1.0.0
    container_name: sphene-engine
    restart: unless-stopped
    ports:
      - "${TARGET_PORT}:80"
    volumes:
      - ./vault:/var/www/html/user/pages/02.knowledge:rw
    environment:
      - SPHENE_ENVIRONMENT=production
      - SPHENE_PORT=${TARGET_PORT}
    healthcheck:
      test: ["CMD-SHELL", "curl -f http://localhost:80/ || exit 1"]
      interval: 20s
      timeout: 5s
      retries: 3
      start_period: 10s
EOF_COMPOSE

# 4. Launch Container
echo -e "\n${BOLD}[4/4] Starting Sphene container via ${COMPOSE_CMD}...${NC}"
$COMPOSE_CMD up -d --force-recreate

echo -e "\nWaiting for Sphene engine health probe..."
MAX_RETRIES=20
COUNTER=0
until curl -s -f "http://127.0.0.1:${TARGET_PORT}" >/dev/null 2>&1 || [ $COUNTER -eq $MAX_RETRIES ]; do
  sleep 2
  COUNTER=$((COUNTER + 1))
  echo -n "."
done

echo -e "\n"
if [ $COUNTER -lt $MAX_RETRIES ]; then
  echo -e "${GREEN}${BOLD}==================================================================${NC}"
  echo -e "${GREEN}${BOLD}  SPHENE KNOWLEDGE HUB IS RUNNING SUCCESSFULLY! ${NC}"
  echo -e "${GREEN}${BOLD}==================================================================${NC}"
  echo -e "  • Web Interface:    ${CYAN}${BOLD}http://localhost:${TARGET_PORT}${NC}"
  echo -e "  • Graph Explorer:   ${CYAN}http://localhost:${TARGET_PORT}/api/graph${NC}"
  echo -e "  • Note REST API:    ${CYAN}http://localhost:${TARGET_PORT}/api/note${NC}"
  echo -e "  • Knowledge Vault:  ${CYAN}$(pwd)/vault/${NC}"
  echo ""
  echo -e "${BOLD}How to use Sphene:${NC}"
  echo -e "  1. ${BOLD}In Browser / Mobile:${NC} Open http://localhost:${TARGET_PORT} to view, edit, search, and click [[Wikilinks]]"
  echo -e "  2. ${BOLD}With Any Markdown / Local Editor:${NC} Open this local folder as your knowledge vault:"
  echo -e "     ${CYAN}$(pwd)/vault/${NC}"
  echo -e "  3. ${BOLD}With Hermes Agent:${NC} Install skill into Hermes:"
  echo -e "     ${CYAN}cp -r hermes-skill/sphene-knowledge-hub ~/.hermes/skills/${NC}"
  echo ""
  echo -e "To stop:  ${CYAN}docker compose down${NC}"
  echo -e "To start: ${CYAN}docker compose up -d${NC}"
  echo -e "Logs:     ${CYAN}docker compose logs -f${NC}"
else
  echo -e "${YELLOW}Container started. Please check http://localhost:${TARGET_PORT} in a few moments.${NC}"
fi
