#!/bin/sh

set -eu

XDG_CFG="${XDG_CONFIG_HOME:-/config/xdg/config}"

mkdir -p "$XDG_CFG"
mkdir -p /downloads

# Force HTTP/HTTPS links opened by SpotiFLAC/Wails
# into our lightweight WebKitGTK browser.
cat > "$XDG_CFG/mimeapps.list" <<'EOF'
[Default Applications]
x-scheme-handler/http=spotiflac-browser.desktop
x-scheme-handler/https=spotiflac-browser.desktop
text/html=spotiflac-browser.desktop
EOF

exec /opt/spotiflac/AppRun
