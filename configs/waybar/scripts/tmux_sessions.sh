#!/bin/bash

MAX_SESSIONS="${TMUX_MAX_SESSIONS:-5}"

# Get all tmux sessions (limit to MAX_SESSIONS)
mapfile -t sessions < <(tmux ls 2>/dev/null | head -n "$MAX_SESSIONS")

# Check if no sessions
if [ ${#sessions[@]} -eq 0 ]; then
  echo '[{"text": "none", "class": "tmux-none"}]'
  exit 0
fi

# Build JSON array
output="["

for session in "${sessions[@]}"; do
  name=$(echo "$session" | cut -d: -f1)
  if echo "$session" | grep -q "(attached)"; then
    status="tmux-attached"
  else
    status="tmux-detached"
  fi
  output+="{\"text\":\"$name\",\"class\":\"$status\"},"
done

# Remove trailing comma, close JSON array
output="${output%,}]"
echo "$output"
