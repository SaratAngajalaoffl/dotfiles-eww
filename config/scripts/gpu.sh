#!/usr/bin/env bash
# Prints NVIDIA GPU usage as a percentage, e.g. "17%"

if ! command -v nvidia-smi &>/dev/null; then
  echo "n/a"
  exit 0
fi

util=$(nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits)
echo "${util}%"
