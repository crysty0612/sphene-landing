#!/usr/bin/env bash
# ==============================================================================
#  SPHENE AEGIS - IN-PLACE ZERO-DEPENDENCY VAULT DECRYPTOR
#  Requires only standard 'openssl' and 'python3' (or pure bash/openssl).
#  Can run on ANY OS (macOS, Linux, WSL, BSD) without Sphene installed.
# ==============================================================================
set -e

BOLD='\033[1m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

VAULT_DIR="${1:-./vault}"
PASSPHRASE="${2}"

echo -e "${CYAN}${BOLD}=== SPHENE AEGIS: IN-PLACE VAULT DECRYPTOR ===${NC}"
echo "Target directory: ${VAULT_DIR}"

if [ ! -d "$VAULT_DIR" ]; then
  echo -e "${RED}[ERROR] Directory '${VAULT_DIR}' does not exist.${NC}"
  exit 1
fi

if [ -z "$PASSPHRASE" ]; then
  read -s -p "Enter Vault Passphrase: " PASSPHRASE
  echo ""
fi

if [ -z "$PASSPHRASE" ]; then
  echo -e "${RED}[ERROR] Passphrase cannot be empty.${NC}"
  exit 1
fi

COUNT=0
FAIL_COUNT=0

for file in $(grep -rl "SPHENE-VAULT:ENCRYPTED:AES256" "$VAULT_DIR" 2>/dev/null); do
  echo -n "Decrypting $(basename "$(dirname "$file")")/$(basename "$file")... "
  
  python3 -c "
import sys, re, subprocess, base64

path = '$file'
passphrase = '''$PASSPHRASE'''

with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

pattern = r'(<!-- SPHENE-VAULT:ENCRYPTED:AES256 -->\s*)([A-Za-z0-9+/=\s]+)(\s*<!-- /SPHENE-VAULT:ENCRYPTED -->)'
m = re.search(pattern, content)
if not m:
    sys.exit(0)

b64_data = ''.join(m.group(2).split())
raw_cipher = base64.b64decode(b64_data)

proc = subprocess.Popen(
    ['openssl', 'enc', '-d', '-aes-256-cbc', '-pbkdf2', '-iter', '100000', '-k', passphrase],
    stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE
)
decrypted, err = proc.communicate(input=raw_cipher)
if proc.returncode != 0:
    print('FAILED (Incorrect passphrase)')
    sys.exit(1)

decrypted_str = decrypted.decode('utf-8', errors='replace')
new_content = content[:m.start()] + decrypted_str + content[m.end():]
new_content = re.sub(r'sealed:\s*true', 'sealed: false', new_content)

with open(path, 'w', encoding='utf-8') as f:
    f.write(new_content)

print('SUCCESS')
" && COUNT=$((COUNT + 1)) || FAIL_COUNT=$((FAIL_COUNT + 1))

done

echo -e "\n${BOLD}Summary:${NC}"
echo -e "  • Notes decrypted: ${GREEN}${COUNT}${NC}"
if [ "$FAIL_COUNT" -gt 0 ]; then
  echo -e "  • Decryption failures: ${RED}${FAIL_COUNT}${NC}"
  exit 1
else
  echo -e "${GREEN}${BOLD}✓ Vault successfully decrypted in-place! All Markdown files are 100% human-readable.${NC}"
fi
