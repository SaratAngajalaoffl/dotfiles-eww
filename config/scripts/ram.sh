#!/usr/bin/env bash
# Prints RAM usage as a percentage, e.g. "25%"

read -r total avail < <(awk '/^MemTotal:/{t=$2} /^MemAvailable:/{a=$2} END{print t, a}' /proc/meminfo)
echo "$(( 100 * (total - avail) / total ))%"
