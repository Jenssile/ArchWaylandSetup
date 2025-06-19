#!/bin/bash

LOW_MAX=${1:-30}
MEDIUM_MAX=${2:-60}

CPU_USAGE_RAW=$(top -bn1 | grep "Cpu(s)" | awk '{print 100 - $8}')
CPU_USAGE=$(printf "%.0f" "$CPU_USAGE_RAW")
TEMP=$(sensors | grep -m 1 -E 'Tctl|Package|temp1' | grep -oP '[0-9.]+(?=°C)')

# Determine usage class
if (( CPU_USAGE <= LOW_MAX )); then
  CLASS="low"
elif (( CPU_USAGE <= MEDIUM_MAX )); then
  CLASS="medium"
else
  CLASS="high"
fi

TEXT="$CPU_USAGE% | ${TEMP}°C"

echo "{\"text\": \"$TEXT\", \"class\": \"$CLASS\"}"
