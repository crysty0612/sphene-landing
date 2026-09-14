---
name: sphene-knowledge-hub
description: >-
  Read, search, create, update, and manage notes, documents, and knowledge in Sphene Knowledge Hub
  (the user's second brain, document store, and knowledge vault). Use whenever the user asks to save
  a document, save as MD, create or read notes, record in their second brain, log daily notes, or
  query the knowledge graph.
version: 1.2.0
metadata:
  hermes:
    tags: [Documents, Notes, Markdown, SecondBrain, KnowledgeBase, Vault, Sphene, DailyNotes]
---

# Sphene Knowledge Substrate (Documents IN & OUT)

Sphene is the user's unified knowledge substrate, document store, and second brain. It stores persistent knowledge as human-auditable, interconnected Markdown files with [[Wikilinks]].

The `sphene` CLI command is globally available in your environment (`sphene`). All operations route through the local Sphene Engine (running on http://127.0.0.1:8743), which mounts the physical vault.

## Critical Guideline: Shell Quoting & Markdown Formatting
When writing multi-line documents containing backticks (```), code blocks, math symbols ($), or quotes, **NEVER pass long markdown in `--body "..."` directly on the command line**, because bash will strip backticks and interpolate variables.

Always use one of the two shell-safe patterns:

### Method 1: Using --file / -f (Recommended for research & long notes)
Write your content to a temporary file using a quoted heredoc (`cat << 'EOF'`), then pass it via `--file`:
```bash
cat << 'NOTE_EOF' > /tmp/note.md
# Note Title

Markdown content with `inline code`, code blocks:
```python
def example():
    return "Safe from bash interpretation"
```

- Links: [[Related Concept]]
NOTE_EOF
sphene write "Note Title" --file /tmp/note.md --tags "tag1,tag2"
rm -f /tmp/note.md
```

### Method 2: Piping via STDIN
You can pipe directly into `sphene write`:
```bash
cat << 'NOTE_EOF' | sphene write "Note Title" --tags "tag1,tag2"
# Note Title
Full markdown content here...
NOTE_EOF
```

### Method 3: Short inline notes only
For simple single-sentence notes without code or backticks:
```bash
sphene write "Quick Idea" --body "Short note linking to [[Architecture]]." --tags "quick"
```

## Reading & Verifying Documents
To read a note or verify that it was saved:
```bash
# Print raw Markdown content directly (ideal for reading or grepping):
sphene read "<slug_or_title>" --raw

# Print complete metadata and JSON envelope:
sphene read "<slug_or_title>"
```
Do NOT run `find /opt/data` searching for notes on disk. Sphene notes are managed through `sphene` CLI commands and the local engine.

## Searching Documents
```bash
sphene search "<query>"
```

## Logging Daily Briefs
```bash
# Via string:
sphene daily --brief "Summary of today's work"

# Via file or heredoc:
cat << 'BRIEF_EOF' | sphene daily
- Fixed deployment script
- Updated knowledge graph
BRIEF_EOF
```

## Inspecting Knowledge Graph & Backlinks
```bash
sphene graph
sphene backlinks "<slug_or_title>"
```

## Territory & Governance
- `00_System/`: Machine memory and scratchpads.
- `10_SecondBrain_Karpathy/`: Shared technical knowledge, architectures, and post-mortems.
- `20_Human_Thinking/`: Strictly protected human cognitive space. Do not write here unless the user explicitly requests it.
