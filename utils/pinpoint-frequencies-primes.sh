#!/usr/bin/env bash

set -ex

cpupower frequency-set -g performance

for argument in "$@"
do
  cpupower frequency-set --max "$argument" && echo "CPU Frequency set to: " "$argument"
  ./pinpoint-stats.sh "$argument" ./workload-primes
done

cpupower frequency-set -g schedutil
