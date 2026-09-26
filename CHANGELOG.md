# Sphene Changelog

All notable changes to the Sphene Sovereign Knowledge Substrate are documented here.

---

## [v2.2.0] - 2026-09-17

### 🎨 Themes & Visual Partition Consistency
- **Drawing Amber Identity**: Replaced purple glow in the drawing partition with a warm, desaturated amber palette (`rgba(245, 158, 11, ...)`) ensuring complete color separation from the Private partition's desaturated purple theme.
- **Theme Palette Harmonization**: Audited and calibrated partition highlights across all supported themes (Dark, Anthracite, Light, Midnight, Sepia, Solarized, and High-Contrast).
- **Interactive Partition Switcher**: Refined sidebar tab indicators, active state backgrounds, and note creation partition bindings.

### 📱 Responsive Mobile Settings Overhaul
- **Zero-Overflow Guarantee**: Restructured all settings tabs (General, Security, Cloud Sync, Tailscale, Partitions, Plugins, Users) to eliminate horizontal clipping on viewport widths down to 360px.
- **Responsive Wrap for Credentials**: Applied `overflow-wrap: anywhere` and `word-break: break-all` to lengthy Tailscale node keys, SHA-256 hashes, and daemon URLs.
- **Mobile Sticky Action Bar**: Enhanced save, revert, and sync actions to stick neatly to the viewport bottom with iOS safe-area support.

### ☁️ Cloud Sync & OAuth Relay Infrastructure
- **Zero-Knowledge OAuth Relay**: Deployed `https://sphene.app/oauth/callback.html` enabling single-click personal Google Drive and Dropbox authentication without requiring users to configure cloud console projects.
- **Origin-Preserving Relay**: Securely forwards OAuth tokens back to local (`http://localhost:8743`) or mesh VPN (`https://*.ts.net`) vault origins via encoded state.
- **Zero-Persistence Policy**: Tokens are processed entirely client-side on the relay page and forwarded via secure hash fragment bounce.

### 🔒 Security, Immutability & Hardened Binaries
- **Source Code Privacy (`-trimpath`)**: Hardened all Go compilation toolchains with `-trimpath` and `-ldflags="-s -w"` to guarantee zero filesystem paths or source code leaks in release binaries.
- **Cryptographic Verification**: Generated cryptographic SHA-256 consistency manifests across all release artifacts.
- **Automated Update Fallbacks**: Enhanced `install.sh` to download from GitHub Release v2.2.0 with transparent fallback to `sphene.app` via Cloudflare 302 redirects.

---

## [v2.1.0] - 2026-09-14
- Integrated modular dynamic plugin engine.
- Differential timeline versioning with Human Veto guardrails.
- Added encrypted partition envelopes with AES-256-GCM.
