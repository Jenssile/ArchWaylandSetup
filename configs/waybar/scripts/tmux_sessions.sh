#!/bin/bash

# Default session display limit
MAX_SESSIONS="${TMUX_MAX_SESSIONS:-3}"

# Get sessions list (just names)
sessions=$(tmux ls 2>/dev/null | cut -d: -f1 | head -n "$MAX_SESSIONS" | xargs)

# Get number of attached sessions
attached_count=$(tmux ls 2>/dev/null | grep -c "(attached)")

if [ -z "$sessions" ]; then
  echo '{"text": "tmux: none", "class": "tmux-none"}'
elif [ "$attached_count" -gt 0 ]; then
  echo "{\"text\": \"tmux: $sessions\", \"class\": \"tmux-attached\"}"
else
  echo "{\"text\": \"tmux: $sessions\", \"class\": \"tmux-detached\"}"
fi
