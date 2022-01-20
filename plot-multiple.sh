#!/usr/bin/env bash

set -e
set -x

if ! command -v gm &> /dev/null
then
  echo "Error: gm (GraphicsMagick) is not installed"
  exit 1
fi

folder="$1"

mkdir -p /tmp/plot-multiple

# Iterate over all arguments but the first
for workload in "${@:2:$#}"
do
  ./plot-evaluation.py -sd --second_plot time --title "$workload" "$workload" "$folder" "/tmp/plot-multiple/$workload.png"
done

gm montage -mode concatenate -tile 3x /tmp/plot-multiple/*.png out.png

rm -rf /tmp/plot-multiple
