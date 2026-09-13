#!/usr/bin/env bash
# ==============================================================================
#  SPHENE 1-CLICK VAULT MIGRATION CLI
#  Migrates standard desktop Markdown vaults to Sphene with 100% fidelity.
# ==============================================================================
set -e

BOLD='\033[1m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'

SOURCE="${1}"
DEST="${2:-/DATA/AppData/sphene/sphene-data/user/pages/02.knowledge}"

echo -e "${CYAN}${BOLD}=== SPHENE 1-CLICK VAULT MIGRATION ===${NC}"

if [ -z "$SOURCE" ]; then
  echo -e "${RED}[ERROR] Please provide source directory or .zip file.${NC}"
  echo "Usage: $0 <path_to_vault_or_zip> [destination_knowledge_dir]"
  exit 1
fi

if [ ! -e "$SOURCE" ]; then
  echo -e "${RED}[ERROR] Source '${SOURCE}' not found.${NC}"
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
python3 "$SCRIPT_DIR/migrate_vault.py" "$SOURCE" --dest "$DEST"

# Invalidate cache if docker container is running
if docker ps --filter "name=sphene-knowledge-hub" --format "{{.Names}}" | grep -q "sphene-knowledge-hub"; then
  docker exec sphene-knowledge-hub sh -c "rm -rf /var/www/html/cache/twig/*" 2>/dev/null || true
  echo -e "${GREEN}✓ Live cache refreshed.${NC}"
fi

echo -e "${GREEN}${BOLD}✓ Migration complete! Refresh your browser to view your notes.${NC}"
