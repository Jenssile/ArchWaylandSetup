#!/bin/bash

# Paths
CONFIG_DIR="$HOME/.config/waybar"
MAIN_CONFIG="$CONFIG_DIR/config"
POPUP_CONFIG="$CONFIG_DIR/config-popup"
POPUP_CSS="$CONFIG_DIR/style-popup.css"
PIDFILE="/tmp/waybar-popup.pid"

if [ -f "$PIDFILE" ]; then
    # Kill popup and remove pid file
    kill "$(cat "$PIDFILE")" && rm "$PIDFILE"
else
    # Read main bar height using jq
    HEIGHT=$(jq '.height' "$MAIN_CONFIG")

    # Generate popup CSS with top margin
    {
        echo "window#waybar { margin-top: ${HEIGHT}px; }"
        cat <<EOF

* {
  font-family: "Fira Sans", "Font Awesome 6 Free";
  font-size: 14px;
}

window#waybar {
  background-color: #3b4252;
  color: #eceff4;
  border-top: 1px solid #81a1c1;
}
EOF
    } > "$POPUP_CSS"

    # Launch popup bar
    waybar -c "$POPUP_CONFIG" -s "$POPUP_CSS" &
    echo $! > "$PIDFILE"
fi
