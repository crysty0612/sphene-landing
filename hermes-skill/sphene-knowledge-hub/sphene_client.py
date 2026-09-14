#!/usr/bin/env python3
"""
Sphene Knowledge Hub Client for Hermes Agent
Supports both direct local filesystem mode and remote HTTP REST mode.
Includes native Sphene Aegis zero-knowledge encryption & decryption support.
"""

import os
import sys
import json
import argparse
import urllib.request
import urllib.error
import urllib.parse
import tempfile
import re
import subprocess
import base64

DEFAULT_SPHENE_URL = os.environ.get("SPHENE_URL", "http://127.0.0.1:8743")
DEFAULT_VAULT_DIR = os.environ.get(
    "SPHENE_VAULT_DIR",
    "/DATA/AppData/sphene/user/pages/02.knowledge"
)
DEFAULT_PASSPHRASE = os.environ.get("SPHENE_VAULT_PASSPHRASE", "")
GLOBAL_ENCRYPT_ALL = os.environ.get("SPHENE_VAULT_ENCRYPT_ALL", "false").lower() in ("1", "true", "yes")

ARMOR_START = "<!-- SPHENE-VAULT:ENCRYPTED:AES256 -->"
ARMOR_END = "<!-- /SPHENE-VAULT:ENCRYPTED -->"
HUMAN_SANDBOX_PREFIXES = ("20_human", "20-human", "human_thinking", "human-thinking")

def slugify(text: str) -> str:
    text = re.sub(r"[^\w\s-]", "", text).strip().lower()
    return re.sub(r"[-\s]+", "-", text)

def encrypt_payload(plaintext: str, passphrase: str) -> str:
    """Encrypt plaintext using universal OpenSSL AES-256-CBC PBKDF2 envelope."""
    if not passphrase:
        raise ValueError("Passphrase required for encryption (pass --passphrase or set SPHENE_VAULT_PASSPHRASE)")
    
    proc = subprocess.Popen(
        ["openssl", "enc", "-aes-256-cbc", "-pbkdf2", "-iter", "100000", "-k", passphrase, "-base64"],
        stdin=subprocess.PIPE,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE
    )
    ciphertext, err = proc.communicate(input=plaintext.encode("utf-8"))
    if proc.returncode != 0:
        raise RuntimeError(f"OpenSSL encryption failed: {err.decode('utf-8', errors='replace')}")
    
    clean_b64 = "".join(ciphertext.decode("utf-8").split())
    return f"{ARMOR_START}\n{clean_b64}\n{ARMOR_END}"

def decrypt_payload(content: str, passphrase: str) -> str:
    """Decrypt armored OpenSSL AES-256-CBC PBKDF2 envelope in-place."""
    if not passphrase:
        raise ValueError("Passphrase required for decryption (pass --passphrase or set SPHENE_VAULT_PASSPHRASE)")
    
    pattern = re.compile(rf"{re.escape(ARMOR_START)}\s*([A-Za-z0-9+/=\s]+)\s*{re.escape(ARMOR_END)}")
    m = pattern.search(content)
    if not m:
        return content
    
    b64_data = "".join(m.group(1).split())
    raw_cipher = base64.b64decode(b64_data)
    
    proc = subprocess.Popen(
        ["openssl", "enc", "-d", "-aes-256-cbc", "-pbkdf2", "-iter", "100000", "-k", passphrase],
        stdin=subprocess.PIPE,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE
    )
    decrypted, err = proc.communicate(input=raw_cipher)
    if proc.returncode != 0:
        raise RuntimeError("Decryption failed (incorrect passphrase or corrupted payload)")
    
    decrypted_str = decrypted.decode("utf-8", errors="replace")
    return content[:m.start()] + decrypted_str + content[m.end():]

class SpheneClient:
    def __init__(self, base_url: str = None, vault_dir: str = None, passphrase: str = None):
        self.base_url = (base_url or os.environ.get("SPHENE_URL", DEFAULT_SPHENE_URL)).rstrip("/")
        self.vault_dir = vault_dir or os.environ.get("SPHENE_VAULT_DIR", DEFAULT_VAULT_DIR)
        self.passphrase = passphrase if passphrase is not None else os.environ.get("SPHENE_VAULT_PASSPHRASE", "")
        self.is_local = os.path.isdir(self.vault_dir)

    def read_note(self, identifier: str, passphrase: str = None) -> dict:
        """Read a note by slug, route, or title, automatically decrypting if sealed."""
        target_slug = slugify(identifier)
        key = passphrase or self.passphrase
        data = None

        # Local mode
        if self.is_local:
            target_path = os.path.join(self.vault_dir, target_slug, "item.md")
            if os.path.isfile(target_path):
                with open(target_path, "r", encoding="utf-8") as f:
                    content = f.read()
                data = {
                    "slug": target_slug,
                    "route": f"/knowledge/{target_slug}",
                    "raw": content,
                    "source": "filesystem"
                }

        # Remote HTTP mode
        if not data:
            url = f"{self.base_url}/api/note?slug={urllib.parse.quote(identifier)}"
            try:
                req = urllib.request.Request(url, headers={"Accept": "application/json"})
                with urllib.request.urlopen(req, timeout=10) as resp:
                    data = json.loads(resp.read().decode("utf-8"))
                    data["source"] = "http"
            except urllib.error.HTTPError as e:
                return {"error": f"HTTP {e.code}: Note '{identifier}' not found"}
            except Exception as e:
                return {"error": f"Failed to connect to Sphene at {self.base_url}: {str(e)}"}

        raw_content = data.get("raw", "")
        is_sealed = ARMOR_START in raw_content or data.get("sealed", False)
        data["sealed"] = is_sealed

        if is_sealed:
            if key:
                try:
                    decrypted_content = decrypt_payload(raw_content, key)
                    data["raw"] = decrypted_content
                    data["decrypted"] = True
                except Exception as e:
                    data["decrypted"] = False
                    data["error_decryption"] = str(e)
            else:
                data["decrypted"] = False
                data["warning"] = "Note is sealed with Sphene Aegis. Pass --passphrase or set SPHENE_VAULT_PASSPHRASE to decrypt."

        return data

    def append_daily_brief(self, brief: str, date_str: str = None) -> dict:
        """Safely append an autonomous agent brief to today's daily note."""
        import datetime
        dt = date_str or datetime.datetime.now().strftime("%Y-%m-%d")
        daily_slug = f"daily-{dt}"
        daily_title = f"Daily Note: {dt}"

        existing = self.read_note(daily_slug)
        existing_body = ""
        tags = ["daily", "journal"]
        if "error" not in existing and "raw" in existing:
            existing_body = existing["raw"]
            tags = existing.get("tags", tags)

        timestamp = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        entry = f"\n\n### 🤖 Autonomous Agent Activity\n- **Timestamp:** {timestamp}\n{brief}\n"

        if existing_body:
            new_body = existing_body.rstrip() + entry
        else:
            new_body = f"# {daily_title}\n\n## Personal Objectives\n- [ ] \n\n## Daily Notes & Reflections\n{entry}"

        return self.write_note(
            title=daily_title,
            body=new_body,
            tags=tags,
            slug=daily_slug,
            override_sandbox=True
        )

    def write_note(self, title: str, body: str, tags: list = None, slug: str = None, sealed: bool = False, passphrase: str = None, override_sandbox: bool = False) -> dict:
        """Atomically write or update a note with [[Wikilinks]] and optional Aegis encryption."""
        if not title:
            return {"error": "Note title is required"}

        tags = tags or []
        note_slug = slug or slugify(title)

        # Agent Sandboxing Check
        is_human_space = any(p in note_slug for p in HUMAN_SANDBOX_PREFIXES) or "human-only" in tags
        if is_human_space and not override_sandbox:
            return {
                "error": "Agent Sandboxing Violation: '20_Human_Thinking' is protected human territory. Machine agents may not write here without explicit human consent (pass --override-sandbox)."
            }

        key = passphrase or self.passphrase
        should_seal = sealed or GLOBAL_ENCRYPT_ALL

        processed_body = body
        if should_seal:
            if not key:
                return {"error": "Sealing requested but no passphrase provided. Pass --passphrase or set SPHENE_VAULT_PASSPHRASE."}
            try:
                processed_body = encrypt_payload(body, key)
            except Exception as e:
                return {"error": f"Encryption failed: {str(e)}"}

        # Local atomic filesystem write
        if self.is_local:
            note_dir = os.path.join(self.vault_dir, note_slug)
            os.makedirs(note_dir, exist_ok=True)
            target_file = os.path.join(note_dir, "item.md")

            tags_str = ", ".join(tags)
            sealed_yaml = "sealed: true\n" if should_seal else ""
            frontmatter = (
                f"---\n"
                f"title: \"{title}\"\n"
                f"{sealed_yaml}"
                f"taxonomy:\n"
                f"  tag: [{tags_str}]\n"
                f"date: 2026-09-14\n"
                f"---\n\n"
            )
            payload = frontmatter + processed_body + "\n"

            with tempfile.NamedTemporaryFile("w", dir=note_dir, delete=False, encoding="utf-8") as tf:
                tf.write(payload)
                temp_name = tf.name

            os.replace(temp_name, target_file)
            os.chmod(target_file, 0o664)

            return {
                "status": "ok",
                "slug": note_slug,
                "route": f"/knowledge/{note_slug}",
                "url": f"/knowledge/{note_slug}",
                "title": title,
                "sealed": should_seal,
                "mode": "atomic_filesystem"
            }

        # Remote HTTP write
        url = f"{self.base_url}/api/note"
        payload = json.dumps({
            "title": title,
            "slug": note_slug,
            "tags": tags,
            "sealed": should_seal,
            "content": processed_body
        }).encode("utf-8")

        req = urllib.request.Request(
            url,
            data=payload,
            headers={"Content-Type": "application/json", "Accept": "application/json"},
            method="POST"
        )
        try:
            with urllib.request.urlopen(req, timeout=10) as resp:
                data = json.loads(resp.read().decode("utf-8"))
                data["sealed"] = should_seal
                data["mode"] = "http_post"
                return data
        except Exception as e:
            return {"error": f"Failed to post note to Sphene: {str(e)}"}

    def seal_note(self, identifier: str, passphrase: str = None) -> dict:
        """In-place seal an existing unencrypted note."""
        key = passphrase or self.passphrase
        if not key:
            return {"error": "Passphrase required to seal note"}

        note = self.read_note(identifier)
        if "error" in note:
            return note
        if note.get("sealed") and ARMOR_START in note.get("raw", ""):
            return {"status": "already_sealed", "slug": note.get("slug")}

        # Strip frontmatter from raw body
        content = note.get("raw", "")
        body = re.sub(r"^---[\s\S]*?---\s*", "", content)
        title = note.get("title", identifier)
        tags = note.get("tags", [])

        return self.write_note(title=title, body=body, tags=tags, slug=note.get("slug"), sealed=True, passphrase=key)

    def unseal_note(self, identifier: str, passphrase: str = None) -> dict:
        """In-place unseal an existing sealed note."""
        key = passphrase or self.passphrase
        if not key:
            return {"error": "Passphrase required to unseal note"}

        note = self.read_note(identifier, passphrase=key)
        if "error" in note:
            return note
        if not note.get("sealed"):
            return {"status": "not_sealed", "slug": note.get("slug")}
        if not note.get("decrypted"):
            return {"error": "Could not decrypt note (incorrect passphrase)"}

        content = note.get("raw", "")
        body = re.sub(r"^---[\s\S]*?---\s*", "", content)
        title = note.get("title", identifier)
        tags = note.get("tags", [])

        return self.write_note(title=title, body=body, tags=tags, slug=note.get("slug"), sealed=False)

    def get_graph(self) -> dict:
        """Retrieve complete knowledge graph nodes and links."""
        url = f"{self.base_url}/api/graph"
        try:
            req = urllib.request.Request(url, headers={"Accept": "application/json"})
            with urllib.request.urlopen(req, timeout=10) as resp:
                return json.loads(resp.read().decode("utf-8"))
        except Exception as e:
            return {"error": f"Failed to fetch graph from {self.base_url}: {str(e)}"}

    def search_notes(self, query: str) -> list:
        """Search graph nodes matching a query string."""
        graph = self.get_graph()
        if "error" in graph:
            return [graph]

        q = query.lower()
        results = []
        for node in graph.get("nodes", []):
            title = node.get("title", "").lower()
            tags = [t.lower() for t in node.get("tags", [])]
            if q in title or any(q in t for t in tags):
                results.append(node)
        return results

    def get_backlinks(self, route_or_slug: str) -> list:
        """Get incoming backlinks for a given route or slug."""
        graph = self.get_graph()
        if "error" in graph:
            return [graph]

        target_slug = slugify(route_or_slug)
        target_route = f"/knowledge/{target_slug}"

        backlinks = []
        for link in graph.get("links", []):
            if link.get("target") == target_route or link.get("target") == route_or_slug:
                backlinks.append(link.get("source"))
        return backlinks


def main():
    parser = argparse.ArgumentParser(description="Sphene Knowledge Hub & Aegis Crypto CLI for Hermes")
    subparsers = parser.add_subparsers(dest="command", required=True)

    # read
    p_read = subparsers.add_parser("read", help="Read a note (auto-decrypts if sealed and passphrase provided)")
    p_read.add_argument("identifier", help="Title or slug of the note")
    p_read.add_argument("-r", "--raw", action="store_true", help="Print raw markdown body directly to stdout without JSON wrapper")
    p_read.add_argument("--passphrase", default=None, help="Vault passphrase for sealed notes")

    # write
    p_write = subparsers.add_parser("write", help="Write/update a note with optional encryption")
    p_write.add_argument("title", help="Title of the note")
    p_write.add_argument("-b", "--body", default="", help="Markdown body content (or '-' for stdin)")
    p_write.add_argument("-f", "--file", default=None, help="File path to read markdown content from (or '-' for stdin)")
    p_write.add_argument("--tags", default="", help="Comma-separated tags")
    p_write.add_argument("--slug", default=None, help="Custom slug")
    p_write.add_argument("--sealed", action="store_true", help="Seal note with AES-256 zero-knowledge encryption")
    p_write.add_argument("--passphrase", default=None, help="Vault passphrase for sealing")
    p_write.add_argument("--override-sandbox", action="store_true", help="Override human sandboxing boundary")

    # daily
    p_daily = subparsers.add_parser("daily", help="Append an autonomous brief to today's daily note")
    p_daily.add_argument("-b", "--brief", default="", help="Autonomous summary or brief to append (or '-' for stdin)")
    p_daily.add_argument("-f", "--file", default=None, help="File path to read brief from (or '-' for stdin)")
    p_daily.add_argument("--date", default=None, help="Target date YYYY-MM-DD")

    # seal
    p_seal = subparsers.add_parser("seal", help="In-place seal an existing note")
    p_seal.add_argument("identifier", help="Title or slug")
    p_seal.add_argument("--passphrase", default=None, help="Vault passphrase")

    # unseal
    p_unseal = subparsers.add_parser("unseal", help="In-place unseal an existing note")
    p_unseal.add_argument("identifier", help="Title or slug")
    p_unseal.add_argument("--passphrase", default=None, help="Vault passphrase")

    # graph
    subparsers.add_parser("graph", help="Dump entire knowledge graph")

    # search
    p_search = subparsers.add_parser("search", help="Search notes by keyword or tag")
    p_search.add_argument("query", help="Search keyword")

    # backlinks
    p_bl = subparsers.add_parser("backlinks", help="Find backlinks pointing to a note")
    p_bl.add_argument("identifier", help="Route or slug")

    args = parser.parse_args()
    cli_passphrase = getattr(args, "passphrase", None) or os.environ.get("SPHENE_VAULT_PASSPHRASE", "")
    client = SpheneClient(passphrase=cli_passphrase)

    if args.command == "read":
        res = client.read_note(args.identifier, passphrase=cli_passphrase)
        if getattr(args, "raw", False):
            if "error" in res:
                print(f"Error: {res['error']}", file=sys.stderr)
                sys.exit(1)
            print(res.get("raw", ""))
        else:
            print(json.dumps(res, indent=2))
    elif args.command == "write":
        tags = [t.strip() for t in args.tags.split(",") if t.strip()]
        body_content = args.body
        if args.file:
            if args.file == "-":
                body_content = sys.stdin.read()
            elif os.path.isfile(args.file):
                with open(args.file, "r", encoding="utf-8") as f:
                    body_content = f.read()
            else:
                print(json.dumps({"error": f"File not found: {args.file}"}, indent=2))
                sys.exit(1)
        elif body_content == "-" or (not body_content and not sys.stdin.isatty()):
            body_content = sys.stdin.read()

        res = client.write_note(
            title=args.title,
            body=body_content,
            tags=tags,
            slug=args.slug,
            sealed=args.sealed,
            passphrase=cli_passphrase,
            override_sandbox=args.override_sandbox
        )
        print(json.dumps(res, indent=2))
    elif args.command == "daily":
        brief_content = args.brief
        if args.file:
            if args.file == "-":
                brief_content = sys.stdin.read()
            elif os.path.isfile(args.file):
                with open(args.file, "r", encoding="utf-8") as f:
                    brief_content = f.read()
            else:
                print(json.dumps({"error": f"File not found: {args.file}"}, indent=2))
                sys.exit(1)
        elif brief_content == "-" or (not brief_content and not sys.stdin.isatty()):
            brief_content = sys.stdin.read()

        if not brief_content:
            print(json.dumps({"error": "Brief content required (use --brief, --file, or stdin)"}, indent=2))
            sys.exit(1)

        res = client.append_daily_brief(brief=brief_content, date_str=args.date)
        print(json.dumps(res, indent=2))
    elif args.command == "seal":
        res = client.seal_note(args.identifier, passphrase=cli_passphrase)
        print(json.dumps(res, indent=2))
    elif args.command == "unseal":
        res = client.unseal_note(args.identifier, passphrase=cli_passphrase)
        print(json.dumps(res, indent=2))
    elif args.command == "graph":
        res = client.get_graph()
        print(json.dumps(res, indent=2))
    elif args.command == "search":
        res = client.search_notes(args.query)
        print(json.dumps(res, indent=2))
    elif args.command == "backlinks":
        res = client.get_backlinks(args.identifier)
        print(json.dumps(res, indent=2))

if __name__ == "__main__":
    main()
