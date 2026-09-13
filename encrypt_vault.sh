#!/usr/bin/env bash
# ==============================================================================
#  SPHENE AEGIS - IN-PLACE ZERO-DEPENDENCY VAULT ENCRYPTOR
# ==============================================================================
set -e

BOLD='\033[1m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'

VAULT_DIR="${1:-./vault}"
PASSPHRASE="${2}"

echo -e "${CYAN}${BOLD}=== SPHENE AEGIS: IN-PLACE VAULT ENCRYPTOR ===${NC}"
echo "Target directory: ${VAULT_DIR}"

if [ ! -d "$VAULT_DIR" ]; then
  echo -e "${RED}[ERROR] Directory '${VAULT_DIR}' does not exist.${NC}"
  exit 1
fi

if [ -z "$PASSPHRASE" ]; then
  read -s -p "Enter Vault Passphrase for Encryption: " PASSPHRASE
  echo ""
fi

if [ -z "$PASSPHRASE" ]; then
  echo -e "${RED}[ERROR] Passphrase cannot be empty.${NC}"
  exit 1
fi

COUNT=0

for file in $(find "$VAULT_DIR" -name "*.md"); do
  # Skip if already encrypted
  if grep -q "SPHENE-VAULT:ENCRYPTED:AES256" "$file"; then
    continue
  fi

  echo -n "Encrypting $(basename "$(dirname "$file")")/$(basename "$file")... "
  
  python3 -c "
import sys, re, subprocess, base64

path = '$file'
passphrase = '''$PASSPHRASE'''

with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

# Separate frontmatter and body
m = re.match(r'^(---\s*[\s\S]*?---\s*)', content)
if m:
    frontmatter = m.group(1)
    body = content[m.end():]
else:
    frontmatter = ''
    body = content

if not body.strip():
    sys.exit(0)

proc = subprocess.Popen(
    ['openssl', 'enc', '-aes-256-cbc', '-pbkdf2', '-iter', '100000', '-k', passphrase, '-base64'],
    stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE
)
ciphertext, err = proc.communicate(input=body.encode('utf-8'))
if proc.returncode != 0:
    print('FAILED')
    sys.exit(1)

clean_b64 = ''.join(ciphertext.decode('utf-8').split())
armored = f'<!-- SPHENE-VAULT:ENCRYPTED:AES256 -->\n{clean_b64}\n<!-- /SPHENE-VAULT:ENCRYPTED -->\n'

if 'sealed:' in frontmatter:
    new_fm = re.sub(r'sealed:\s*false', 'sealed: true', frontmatter)
elif frontmatter:
    new_fm = re.sub(r'(---\s*)$', 'sealed: true\n---', frontmatter.strip()) + '\n\n'
else:
    new_fm = '---\nsealed: true\n---\n\n'

with open(path, 'w', encoding='utf-8') as f:
    f.write(new_fm + armored)

print('SUCCESS')
" && COUNT=$((COUNT + 1))

done

echo -e "\n${GREEN}${BOLD}✓ Encrypted ${COUNT} notes with Sphene Aegis.${NC}"
