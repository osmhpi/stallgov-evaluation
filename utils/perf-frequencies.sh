#!/usr/bin/env bash

set -x
set -e

cpupower frequency-set -g performance

for argument in "$@"
do
  cpupower frequency-set --max "$argument" && echo "CPU Frequency set to: " "$argument"
  perf stat -r 5 -e cycle_activity.stalls_l3_miss memory-bound/target/release/memory-bound 2> "$argument.txt"
done
