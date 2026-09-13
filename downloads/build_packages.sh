#!/usr/bin/env bash
set -e

PKG_DIR="/tmp/sphene_deb_build"
rm -rf "$PKG_DIR"
mkdir -p "$PKG_DIR/DEBIAN"
mkdir -p "$PKG_DIR/usr/local/bin"
mkdir -p "$PKG_DIR/usr/share/applications"
mkdir -p "$PKG_DIR/usr/share/pixmaps"

cat << "CTRL" > "$PKG_DIR/DEBIAN/control"
Package: sphene
Version: 1.1.0
Section: utils
Priority: optional
Architecture: all
Maintainer: Sphene Core Team <team@sphene.app>
Description: Sovereign Knowledge Substrate for Humans and Autonomous AI
 Desktop launcher and CLI client for Sphene Knowledge Hub.
CTRL

cat << "LAUNCH" > "$PKG_DIR/usr/local/bin/sphene-app"
#!/usr/bin/env bash
echo "Launching Sphene Knowledge Hub..."
if command -v xdg-open >/dev/null 2>&1; then
  xdg-open "http://localhost:8743" || xdg-open "https://sphene.app"
elif command -v sensible-browser >/dev/null 2>&1; then
  sensible-browser "http://localhost:8743"
else
  echo "Please open http://localhost:8743 in your browser."
fi
LAUNCH
chmod 755 "$PKG_DIR/usr/local/bin/sphene-app"

cp /DATA/AppData/sphene/sphene-landing/assets/icons/icon-512.png "$PKG_DIR/usr/share/pixmaps/sphene.png"

cat << "DESK" > "$PKG_DIR/usr/share/applications/sphene.desktop"
[Desktop Entry]
Name=Sphene Knowledge Hub
Comment=Sovereign Knowledge Substrate for Humans & Autonomous AI
Exec=/usr/local/bin/sphene-app
Icon=sphene
Terminal=false
Type=Application
Categories=Office;Utility;Development;
DESK

dpkg-deb --build "$PKG_DIR" /DATA/AppData/sphene/sphene-landing/downloads/sphene_1.1.0_all.deb
echo "✓ sphene_1.1.0_all.deb built successfully."

# Windows Launcher Package
WIN_DIR="/tmp/sphene_win_build"
rm -rf "$WIN_DIR"
mkdir -p "$WIN_DIR"

cat << "BAT" > "$WIN_DIR/Launch-Sphene.bat"
@echo off
title Sphene Knowledge Hub
echo ========================================================
echo   Sphene Knowledge Hub - Sovereign Desktop Launcher
echo ========================================================
echo Checking for local Sphene engine...
start http://localhost:8743
exit
BAT

cat << "PS1" > "$WIN_DIR/Install-Sphene-Desktop.ps1"
Write-Host "Creating Sphene Knowledge Hub Desktop Shortcut..." -ForegroundColor Cyan
$WshShell = New-Object -comObject WScript.Shell
$Shortcut = $WshShell.CreateShortcut("$Home\Desktop\Sphene.lnk")
$Shortcut.TargetPath = "$PSScriptRoot\Launch-Sphene.bat"
$Shortcut.Description = "Sphene Knowledge Hub"
$Shortcut.Save()
Write-Host "✓ Sphene Desktop shortcut created!" -ForegroundColor Green
Start-Process "http://localhost:8743"
PS1

(cd /tmp && zip -r /DATA/AppData/sphene/sphene-landing/downloads/sphene-windows-launcher-v1.1.0.zip sphene_win_build/*)
echo "✓ Windows launcher packaged successfully."

rm -rf "$PKG_DIR" "$WIN_DIR"
