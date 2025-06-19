#!/bin/bash

LOW_MAX=${1:-30}
MEDIUM_MAX=${2:-60}

MEM_USED=$(free | awk '/Mem:/ {printf("%.0f", $3/$2 * 100)}')

if (( MEM_USED <= LOW_MAX )); then
  CLASS="low"
elif (( MEM_USED <= MEDIUM_MAX )); then
  CLASS="medium"
else
  CLASS="high"
fi

USAGE=$(free -h | awk '/Mem:/ {print $3 "/" $2}')
echo "{\"text\": \"$USAGE\", \"class\": \"$CLASS\"}"
