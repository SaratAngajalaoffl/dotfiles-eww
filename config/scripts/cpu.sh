#!/usr/bin/env bash
# Prints CPU usage as a percentage, e.g. "18%"

read -r _ u1 n1 s1 i1 w1 x1 y1 z1 _ _ < /proc/stat
sleep 0.2
read -r _ u2 n2 s2 i2 w2 x2 y2 z2 _ _ < /proc/stat

prev_idle=$((i1 + w1))
idle=$((i2 + w2))
prev_total=$((u1 + n1 + s1 + i1 + w1 + x1 + y1 + z1))
total=$((u2 + n2 + s2 + i2 + w2 + x2 + y2 + z2))

diff_total=$((total - prev_total))
diff_idle=$((idle - prev_idle))

if [ "$diff_total" -le 0 ]; then
  echo "0%"
else
  echo "$(( (100 * (diff_total - diff_idle)) / diff_total ))%"
fi
