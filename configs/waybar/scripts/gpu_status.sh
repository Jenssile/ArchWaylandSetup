#!/bin/bash

LOW_MAX=${1:-30}
MEDIUM_MAX=${2:-60}

DEDICATED_GPU=$(lspci | grep -E "VGA|3D" | grep -i 'AMD' | grep -v "APU")
if [[ -z "$DEDICATED_GPU" ]]; then
  echo ""
  exit 0
fi

USAGE=0
if command -v radeontop &> /dev/null; then
  USAGE=$(radeontop -d - -l 1 | awk '/gpu/ {gsub("%", "", $2); print int($2)}' | head -n 1)
fi

TEMP=$(sensors | grep -m 1 -E 'edge|temp1' | grep -oE '[0-9.]+°C')

if (( USAGE <= LOW_MAX )); then
  CLASS="low"
elif (( USAGE <= MEDIUM_MAX )); then
  CLASS="medium"
else
  CLASS="high"
fi

echo "{\"text\": \"${USAGE}% | $TEMP\", \"class\": \"$CLASS\"}"
