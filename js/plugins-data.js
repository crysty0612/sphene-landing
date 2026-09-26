/**
 * Sphene Sovereign 23 Native Plugins Catalog
 * Structured dataset powering Overview Panes, Search, and Detailed Modal Views.
 */
const SPHENE_PLUGINS = [
  // 1. Visual & Diagrams
  {
    id: "drawing-studio",
    name: "Drawing Studio & Visual Diagrams",
    category: "visual",
    categoryName: "Visual & Canvas",
    icon: "🎨",
    badge: "⚡ < 5ms",
    tagline: "Infinite visual canvas for architecture diagrams, flowcharts, and freehand sketches.",
    image: "/assets/screenshots/app_drawing_studio_flow.png",
    overview: "A hardware-accelerated visual studio embedded directly into the Sphene workspace. Allows software architects, researchers, and system designers to create freeform diagrams with vector geometry, sticky arrow connections, and real-time Markdown/Mermaid synchronization.",
    specs: {
      latency: "< 5.0 ms",
      hostRam: "0 MB (Client Canvas)",
      engine: "Native HTML5 Canvas & SVG"
    },
    capabilities: [
      "Vector geometry tools: rectangles, diamonds, circles, cylinders, and text labels",
      "Sticky connectors with automatic orthogonal path routing",
      "Freehand pencil and multi-color highlighter with pressure smoothing",
      "Bi-directional sync with standard Markdown notes and Mermaid blocks",
      "1-Click export to clean SVG and high-resolution PNG"
    ],
    bestFor: "Architecture diagrams, cloud infrastructure topologies, process workflows, visual brainstorming.",
    shortcut: "Command Palette: /draw or Top Toolbar Canvas Icon"
  },
  {
    id: "mermaid",
    name: "Mermaid & Interactive Flowcharts",
    category: "visual",
    categoryName: "Visual & Canvas",
    icon: "📊",
    badge: "SVG Engine",
    tagline: "Inline SVG diagram engine rendering sequence charts, state machines, and Gantt charts directly from Markdown.",
    image: "/assets/screenshots/app_editor_main_dark.png",
    overview: "Built-in parser for Mermaid diagram syntax. Write clean code blocks inside standard Markdown notes and instantly watch them compile into interactive, high-contrast SVG graphics.",
    specs: {
      latency: "< 0.05 ms",
      hostRam: "0 MB (Client parser)",
      engine: "Client-Side SVG Compiler"
    },
    capabilities: [
      "Sequence diagrams, state machines, and class hierarchies",
      "Git commit graphs and Gantt timeline scheduling",
      "Auto-adapts to Sphene dark and light themes dynamically",
      "Interactive pan and zoom directly inside note preview"
    ],
    bestFor: "Software engineering specs, protocol flows, database ER diagrams.",
    shortcut: "```mermaid code blocks"
  },
  {
    id: "pdf-exporter",
    name: "High-Fidelity PDF Exporter",
    category: "visual",
    categoryName: "Visual & Canvas",
    icon: "📄",
    badge: "1-Click",
    tagline: "Converts Markdown documents into clean, professional PDF files directly in the browser.",
    image: "",
    overview: "Client-side document compiler tailored for publication. Renders Markdown notes with print typography, mathematical formulas, syntax-highlighted code, and frontmatter metadata headers without external cloud rendering.",
    specs: {
      latency: "Sub-second",
      hostRam: "0 MB (Native CSS Paged Media)",
      engine: "Browser Print Engine"
    },
    capabilities: [
      "Preserves custom CSS styling, tables, and callout quote blocks",
      "Automatic page breaks with intelligent orphan/widow prevention",
      "Frontmatter author, date, and version headers included automatically",
      "Zero telemetry and zero external web service roundtrips"
    ],
    bestFor: "Sharing research papers, executive memos, technical documentation handoffs.",
    shortcut: "File Menu > Export PDF or Cmd/Ctrl + P"
  },
  {
    id: "graphylink",
    name: "GraphyLink: Dynamic Knowledge Graph",
    category: "visual",
    categoryName: "Visual & Canvas",
    icon: "🕸️",
    badge: "⚡ < 1ms",
    tagline: "Interactive 2-hop local graph showing incoming backlinks, forward wikilinks, and cluster relationships.",
    image: "/assets/screenshots/app_knowledge_graph_view.png",
    overview: "A dynamic physics-driven knowledge graph companion. Tracks your active document in real time, projecting adjacent notes, references, and conceptual clusters with sub-millisecond physics simulations.",
    specs: {
      latency: "< 0.20 ms query",
      hostRam: "0 MB (Canvas 2D / WebGL)",
      engine: "Force-Directed Physics Simulation"
    },
    capabilities: [
      "Interactive 2-hop neighbor expansion around active note",
      "Color-coded node clustering by vault partition (Inbox, Work, Reference)",
      "Instant node filtering by tags, folder, and link density",
      "Direct jump-navigation on node click"
    ],
    bestFor: "Visualizing conceptual density, discovering hidden research bridges, second brain exploration.",
    shortcut: "Split-Pane Graph Toggle or Cmd/Ctrl + G"
  },
  {
    id: "gallery-lightbox",
    name: "Gallery Pane & Image Lightbox",
    category: "visual",
    categoryName: "Visual & Canvas",
    icon: "🖼️",
    badge: "Lightbox",
    tagline: "Aggregates diagrams and photos across documents with interactive zoom, pan, and carousel navigation.",
    image: "",
    overview: "Automatically indexes all visual media in your active document or folder into a clean gallery view. Clicking any image launches a full-screen lightbox with smooth pan, zoom, and previous/next carousel controls.",
    specs: {
      latency: "Instant",
      hostRam: "0 MB",
      engine: "Hardware-accelerated CSS Transforms"
    },
    capabilities: [
      "Full-screen inspection for architecture diagrams and high-res schematics",
      "Smooth zoom (up to 400%) with drag-to-pan inspection",
      "Caption extraction from Markdown alt text",
      "Keyboard shortcut navigation (Arrow keys, Esc to exit)"
    ],
    bestFor: "High-resolution diagram review, design inspiration boards, photography notes.",
    shortcut: "Click any inline image in editor"
  },

  // 2. Sovereign AI & Intelligence
  {
    id: "webllm",
    name: "Sovereign WebLLM & Micro-AI Assistant",
    category: "ai",
    categoryName: "Sovereign AI",
    icon: "🤖",
    badge: "100% Private",
    tagline: "Private on-device AI assistant for synthesis, summaries, and conversational Q&A with paragraph attribution.",
    image: "/assets/screenshots/app_micro_ai_assistant.png",
    overview: "A fully private on-device AI co-pilot. Delivers contextual document summaries, bullet-point syntheses, and conversational question answering. Operates with complete note privacy and zero external API subscriptions.",
    specs: {
      latency: "0.70 ms extraction",
      hostRam: "< 80 KB (Featherweight)",
      engine: "TextRank Saliency & Heuristics"
    },
    capabilities: [
      "Paragraph-level source attribution: click citations to smooth-scroll directly to target text",
      "Abstractive document synthesis and key takeaway extraction",
      "Multi-turn conversational Q&A grounded strictly in the active note",
      "Zero telemetry: raw note text never leaves your device"
    ],
    bestFor: "In-depth note synthesis, academic literature review, quick answers over long technical notes.",
    shortcut: "Right Sidebar AI Toggle or Cmd/Ctrl + J"
  },
  {
    id: "semantic-backlinks",
    name: "Micro Semantic AI: Auto-Backlinks",
    category: "ai",
    categoryName: "Sovereign AI",
    icon: "🧠",
    badge: "⚡ 2.27 ms",
    tagline: "Sub-millisecond vector cosine distance surfacing related notes automatically without manual [[links]].",
    image: "",
    overview: "Calculates sub-millisecond vector similarity across note paragraphs using client-side TF-IDF embeddings and cosine similarity. Automatically suggests relevant notes and serendipitous connections as you write.",
    specs: {
      latency: "2.27 ms",
      hostRam: "< 100 KB (Zero Lag)",
      engine: "Vector Cosine Metric Engine"
    },
    capabilities: [
      "Surfaces conceptually related notes with match confidence percentages (e.g., 94% Match)",
      "Zero manual tagging or [[wikilink]] overhead required",
      "Operates 100% locally in browser memory with zero external API calls",
      "Updates in the background during document save"
    ],
    bestFor: "Zettelkasten research, serendipitous discovery, uncovering forgotten literature notes.",
    shortcut: "Document Footer > 'Related Notes' Pane"
  },
  {
    id: "smart-router",
    name: "Smart Inbox Router & Topic Classifier",
    category: "ai",
    categoryName: "Sovereign AI",
    icon: "🏷️",
    badge: "⚡ 1.98 ms",
    tagline: "Centroid-based topic clustering suggesting YAML frontmatter tags and destination folders.",
    image: "",
    overview: "Evaluates incoming quick-notes and dumps into your Inbox partition. Automatically proposes optimal frontmatter tags and folder destinations using centroid topic clustering, requiring only a single click to confirm.",
    specs: {
      latency: "1.98 ms",
      hostRam: "0 MB",
      engine: "Centroid Topic Classifier"
    },
    capabilities: [
      "Non-destructive suggestion card displayed at the top of new notes",
      "Auto-generates clean YAML frontmatter with tags and folder taxonomy",
      "Learns vault organization patterns automatically",
      "1-Click apply or dismiss without touching original content"
    ],
    bestFor: "Inbox triage, automated tag taxonomy, zero cognitive sorting overhead.",
    shortcut: "Automatic on new Inbox note creation"
  },
  {
    id: "entity-extractor",
    name: "In-Memory Entity & Citation Extractor",
    category: "ai",
    categoryName: "Sovereign AI",
    icon: "⚡",
    badge: "< 0.01 ms",
    tagline: "High-speed token engine detecting dates, URLs, references, and citations in real time.",
    image: "",
    overview: "A lightweight AST-integrated token engine that scans note content on each keystroke to detect dates, external URLs, arXiv citations, and task items with zero perceptible latency.",
    specs: {
      latency: "< 0.01 ms (50x scan)",
      hostRam: "0 MB",
      engine: "In-Memory Regex Tokenizer"
    },
    capabilities: [
      "Auto-detects ISO dates and converts them into 1-click links to daily journals",
      "Parses arXiv paper IDs and book citations with rich preview metadata",
      "Runs continuously in the background without UI lag or memory leaks",
      "Zero network requests"
    ],
    bestFor: "Academic papers, journal linking, automated citation management.",
    shortcut: "Live background parser"
  },
  {
    id: "hermes-mcp",
    name: "Hermes & Claude Model Context Protocol (MCP)",
    category: "ai",
    categoryName: "Sovereign AI",
    icon: "🔌",
    badge: "Aegis Guarded",
    tagline: "Connects external autonomous AI agents to your vault with strict partition boundaries.",
    image: "",
    overview: "Built-in native MCP server enabling local autonomous agents like Hermes, Claude Desktop, and Ollama agents to search, read, and write notes within cryptographically enforced partition boundaries.",
    specs: {
      latency: "< 0.50 ms RPC",
      hostRam: "< 5 MB",
      engine: "Standard JSON-RPC Model Context Protocol"
    },
    capabilities: [
      "Exposes standard MCP tools: `search_notes`, `read_note`, `append_to_note`",
      "Aegis partition governance prevents agents from modifying Reference or System notes",
      "Auditable tool execution log with rollback checkpoints",
      "Compatible with Claude Desktop, Hermes Agent CLI, and custom LLM sidecars"
    ],
    bestFor: "Autonomous agent workflows, second brain research sidecars, automated daily digests.",
    shortcut: "Settings > MCP Server Endpoint"
  },

  // 3. Knowledge Ingestion & Bridges
  {
    id: "bookify",
    name: "Bookify Universal Web & Book Splitter",
    category: "ingestion",
    categoryName: "Knowledge & Importers",
    icon: "📚",
    badge: "AST Sanitizer",
    tagline: "Strips ads and clutter from web articles and splits multi-chapter books into linked notes.",
    image: "",
    overview: "Clean web content extraction engine and book splitter. Removes advertising, cookie banners, navigation menus, and tracker noise, and intelligently splits large ePubs or long texts into chapter-based Markdown notes with a master Table of Contents.",
    specs: {
      latency: "Instant AST",
      hostRam: "0 MB",
      engine: "DOM Readability AST Parser"
    },
    capabilities: [
      "One-click URL ingestion into clean, local Markdown",
      "Splits long books into chapter notes with forward/backward [[Wikilinks]]",
      "Generates master index file with auto-linked Table of Contents",
      "Downloads and preserves inline images locally in vault"
    ],
    bestFor: "Archiving web essays, technical ePub books, clutter-free offline reading.",
    shortcut: "Import Menu > Web / Book Splitter"
  },
  {
    id: "readwise",
    name: "Readwise & Kindle Highlights Bridge",
    category: "ingestion",
    categoryName: "Knowledge & Importers",
    icon: "📖",
    badge: "Direct Sync",
    tagline: "Synchronizes curated book highlights and Kindle clippings directly into your Reference partition.",
    image: "",
    overview: "Direct synchronization bridge for Kindle clippings and Readwise libraries. Ingests books, articles, and podcasts into clean Markdown literature notes with author metadata, chapter titles, and quote blocks.",
    specs: {
      latency: "Background Sync",
      hostRam: "0 MB",
      engine: "Direct HTTPS Sync Adapter"
    },
    capabilities: [
      "Syncs directly into the immutable Reference partition where AI cannot mutate it",
      "Preserves original page numbers, location tags, and user notes",
      "Incremental syncing ensures no duplicate notes or deleted highlight churn",
      "Auto-generates tags for author, genre, and reading status"
    ],
    bestFor: "Avid Kindle readers, literature synthesis, permanent quote repositories.",
    shortcut: "Settings > Readwise Bridge"
  },
  {
    id: "google-keep",
    name: "Google Keep Notes & Checklist Importer",
    category: "ingestion",
    categoryName: "Knowledge & Importers",
    icon: "📱",
    badge: "1-Click",
    tagline: "Converts Google Keep archives and exports into clean Markdown, checklists, and tags.",
    image: "",
    overview: "Direct parser for Google Takeout Keep archives. Converts quick mobile memos, color-coded notes, and checklists into clean Markdown with frontmatter metadata.",
    specs: {
      latency: "1-Click Batch",
      hostRam: "0 MB",
      engine: "JSON AST Transformer"
    },
    capabilities: [
      "Preserves Keep note background colors as YAML metadata",
      "Converts Keep labels into standard `#tags`",
      "Transforms Keep todo checklists into interactive markdown `- [ ]` checkboxes",
      "Imports attached images directly into note attachment folders"
    ],
    bestFor: "Escaping Google Keep, moving mobile scratchpads into your permanent second brain.",
    shortcut: "Settings > Importers > Google Keep"
  },
  {
    id: "google-drive",
    name: "Google Drive Cloud Ingestion",
    category: "ingestion",
    categoryName: "Knowledge & Importers",
    icon: "☁️",
    badge: "GCP Direct",
    tagline: "Authenticates with Google Cloud to browse remote Drive folders and import Docs into local Markdown.",
    image: "",
    overview: "Native Google Cloud client allowing authenticated browsing and selective download of Google Drive documents, spreadsheets, and files directly into local Markdown notes.",
    specs: {
      latency: "Direct Stream",
      hostRam: "0 MB",
      engine: "Direct OAuth 2.0 / Service Account"
    },
    capabilities: [
      "Zero telemetry: communicates directly with Google API from your own machine",
      "Converts Google Docs formatting into standard Markdown tables and callouts",
      "Selective folder import: pull only what you need into your vault",
      "Supports Service Account JSON keys or interactive OAuth"
    ],
    bestFor: "Pulling team documentation out of Google Drive into sovereign local storage.",
    shortcut: "Settings > Importers > Google Drive"
  },
  {
    id: "vault-migrator",
    name: "1-Click Desktop Vault Importer",
    category: "ingestion",
    categoryName: "Knowledge & Importers",
    icon: "📁",
    badge: "100% Fidelity",
    tagline: "Seamlessly imports standard desktop Markdown and Foam vaults with zero formatting loss.",
    image: "",
    overview: "Automated ingestion pipeline for importing standard desktop Markdown vaults. Preserves folder structures, frontmatter schemas, [[Wikilinks]], and images while immediately generating SQLite FTS5 search indexes.",
    specs: {
      latency: "< 30s (10k notes)",
      hostRam: "0 MB Host Overhead",
      engine: "Native Go Ingestion Pipeline"
    },
    capabilities: [
      "100% fidelity: preserves existing folder structures, tags, and internal links",
      "Translates Dataview queries into native Sphene high-performance lookups",
      "Imports all images, PDFs, and binary attachments seamlessly",
      "Immediate indexing for sub-0.20ms search"
    ],
    bestFor: "Migrating from Electron-heavy desktop apps without manual reformatting.",
    shortcut: "CLI: `bash migrate_vault.sh` or Web Importer"
  },

  // 4. Security, Backup & Integrity
  {
    id: "git-backup",
    name: "Cryptographic Git Auto-Commit & Backup",
    category: "security",
    categoryName: "Security & Backup",
    icon: "🔒",
    badge: "Ed25519 Sign",
    tagline: "Automated snapshot engine creating signed Git restore points on vault modifications.",
    image: "",
    overview: "Continuous automated version control. Monitors vault changes and creates incremental Git commits signed with cryptographic attestations whenever you pause writing.",
    specs: {
      latency: "Background idle",
      hostRam: "Minimal",
      engine: "Native Git Engine"
    },
    capabilities: [
      "Automated commit-on-idle: snapshots changes without interrupting writing flow",
      "Cryptographic commit signatures guarantee history integrity",
      "Branch-based version history allows instant visual diffing",
      "One-click push to any private remote Git repository"
    ],
    bestFor: "Accidental edit recovery, full historical audits, off-site disaster backups.",
    shortcut: "Settings > Version Control"
  },
  {
    id: "ast-linter",
    name: "Markdown & Wikilink AST Linter",
    category: "security",
    categoryName: "Security & Backup",
    icon: "🔍",
    badge: "AST Linter",
    tagline: "Sub-millisecond AST parser scanning vault for dead [[links]], orphan notes, and frontmatter errors.",
    image: "",
    overview: "Vault health monitoring utility. Scans your entire knowledge substrate in milliseconds to find broken internal links, notes with zero connections, and YAML syntax errors.",
    specs: {
      latency: "< 50 ms full vault",
      hostRam: "0 MB",
      engine: "Sub-millisecond AST Scanner"
    },
    capabilities: [
      "Identifies broken [[Wikilinks]] and suggests closest filename matches",
      "Detects isolated orphan notes with zero inbound or outbound links",
      "Validates YAML frontmatter tags, dates, and schema constraints",
      "Batch 1-click repair for renamed file references"
    ],
    bestFor: "Maintaining a pristine, well-connected second brain across thousands of notes.",
    shortcut: "Command Palette > Run Vault Linter"
  },
  {
    id: "trash-bin",
    name: "Sovereign Trash & Safe Restore Bin",
    category: "security",
    categoryName: "Security & Backup",
    icon: "🗑️",
    badge: "Soft-Delete",
    tagline: "Soft-delete buffer preventing accidental note loss with 1-click preview and instant restore.",
    image: "",
    overview: "Non-destructive deletion shield. When you delete notes, they are moved to a protected `.sphene/trash/` staging partition with full markdown previews and instant restore buttons.",
    specs: {
      latency: "Instant",
      hostRam: "0 MB",
      engine: "Filesystem Soft-Delete Guard"
    },
    capabilities: [
      "Zero accidental data loss: deleted notes are preserved until manual purge",
      "Full document preview before deciding to restore or permanently remove",
      "Restores notes back to their exact original folder path",
      "Bulk purge option with confirmation safeguards"
    ],
    bestFor: "Fearless vault reorganization, cleaning up draft notes safely.",
    shortcut: "File Tree > Trash Bin"
  },
  {
    id: "aegis-partitions",
    name: "Aegis 4-Zone Security Partitions",
    category: "security",
    categoryName: "Security & Backup",
    icon: "🛡️",
    badge: "< 0.20ms Guard",
    tagline: "Hardware-like read/write boundaries isolating AI agents from sensitive reference notes.",
    image: "",
    overview: "Architectural security boundaries dividing your vault into 4 distinct cryptographic zones: Inbox (Scratchpad), Work (Active Projects), Reference (Immutable Literature), and System (Configuration). Enforces strict write restrictions on external AI agents.",
    specs: {
      latency: "< 0.20 ms",
      hostRam: "0 MB",
      engine: "Kernel File Access Boundary"
    },
    capabilities: [
      "Guarantees external AI agents cannot modify or delete literature or permanent reference notes",
      "Clear separation of ephemeral scratch notes from published work",
      "Prevents prompt-injection attacks from corrupting your permanent knowledge",
      "Zero performance overhead"
    ],
    bestFor: "Safe AI agent experimentation, research protection, enterprise compliance.",
    shortcut: "Configured via `.sphene/partitions.json`"
  },

  // 5. Focus, Reading & Ergonomics
  {
    id: "katex",
    name: "KaTeX Fast LaTeX Formula Renderer",
    category: "reading",
    categoryName: "Focus & Reading",
    icon: "∑",
    badge: "KaTeX Fast",
    tagline: "High-speed mathematical typesetting for inline $...$ and block $$...$$ equations.",
    image: "/assets/screenshots/app_theme_antracite_math.png",
    overview: "Embedded mathematical rendering engine powered by KaTeX. Formats complex scientific formulas, calculus expressions, matrices, and Greek notation at lightning speed without external fonts or cloud calls.",
    specs: {
      latency: "< 0.10 ms render",
      hostRam: "0 MB",
      engine: "KaTeX WebAssembly Engine"
    },
    capabilities: [
      "Instant inline math with `$x^2 + y^2 = z^2$` and block formulas with `$$...$$`",
      "Matrices, calculus symbols, and multi-line equation arrays",
      "Full high-contrast rendering across all light and dark themes",
      "Zero layout shifts while typing"
    ],
    bestFor: "STEM researchers, machine learning practitioners, physicists, engineers.",
    shortcut: "Inline `$...$` or block `$$...$$`"
  },
  {
    id: "dynamic-toc",
    name: "Dynamic Floating Table of Contents",
    category: "reading",
    categoryName: "Focus & Reading",
    icon: "📑",
    badge: "Smooth Jump",
    tagline: "Unobtrusive floating outline extracting heading hierarchy with smooth jump navigation.",
    image: "",
    overview: "A lightweight floating navigation drawer that dynamically reflects document headings (H1–H6). Tracks your scroll position in real time and lets you jump between sections effortlessly.",
    specs: {
      latency: "Instant AST",
      hostRam: "0 MB",
      engine: "Dynamic Heading Observer"
    },
    capabilities: [
      "Real-time heading hierarchy extraction from active document",
      "Highlights the current section as you scroll through long notes",
      "Click-to-jump with smooth acceleration and deceleration",
      "Collapsible to save screen real estate on smaller monitors"
    ],
    bestFor: "Long-form technical documentation, research papers, book notes.",
    shortcut: "Top Toolbar Outline Icon"
  },
  {
    id: "interactive-tasks",
    name: "Interactive Task Matrix & Checkbox Sorter",
    category: "reading",
    categoryName: "Focus & Reading",
    icon: "☑️",
    badge: "Vault-Wide",
    tagline: "Aggregates task checkboxes across all documents into a centralized interactive board.",
    image: "",
    overview: "A vault-wide task aggregation view. Automatically discovers and parses standard Markdown checklist items (`- [ ]`) across all notes, allowing you to filter, sort, and toggle tasks directly without opening each note.",
    specs: {
      latency: "< 2.0 ms query",
      hostRam: "0 MB",
      engine: "SQLite AST Task Aggregator"
    },
    capabilities: [
      "Interactive 1-click toggling instantly updates the underlying Markdown file on disk",
      "Filter tasks by tag, folder, completion status, or document date",
      "Group tasks by project or view as a unified daily agenda",
      "Preserves original document formatting"
    ],
    bestFor: "Cross-project task management, sprint tracking, daily action checklists.",
    shortcut: "Sidebar Tasks Icon"
  },
  {
    id: "curated-themes",
    name: "5 Curated High-Legibility Themes",
    category: "reading",
    categoryName: "Focus & Reading",
    icon: "🎨",
    badge: "5 Presets",
    tagline: "Handcrafted palettes designed for maximum typography contrast and zero eye strain.",
    image: "/assets/screenshots/app_theme_cyber_velvet.png",
    overview: "5 bespoke visual palettes engineered for long-duration reading and writing: Minimalist Dark (OLED Pure Black), Minimalist White (Paper Editorial), Google Material 3, Cyber Velvet Rock, and Antracite (Monochrome Grey).",
    specs: {
      latency: "0.0 ms switch",
      hostRam: "0 MB",
      engine: "Pure CSS Design Tokens"
    },
    capabilities: [
      "OLED Minimalist Dark saves battery and minimizes eye fatigue in dark rooms",
      "Antracite Monochrome Grey provides distraction-free technical focus",
      "Cyber Velvet Rock brings vivid modern aesthetic contrast",
      "Instant theme switching with zero page reload"
    ],
    bestFor: "Late-night writing sessions, daylight outdoor reading, ergonomic comfort.",
    shortcut: "Navigation Theme Switcher"
  }
];

// Export or attach to window
window.SPHENE_PLUGINS = SPHENE_PLUGINS;
