#!/bin/env bash

set -e

if [[ ! -f "frequencies.config" ]]; then
  echo "frequencies.config does not exist!"
  echo "It must be a file with all frequencies to evaluate on the first line (separated by space)"
  exit 1
fi

if [ "$EUID" -ne 0 ]; then 
    echo "Please run this command as root!"
    exit 1
fi

GOVERNOR=$(cpupower frequency-info -p | awk '/^.+The governor/ { gsub(/"/,""); print $3 }')

for workload in "$@"
do
  echo "####### Running workload ${workload} ##########"

  workload_name=$(basename "$workload")
  set -x
  cpupower frequency-set -g memutil
  ../utils/pinpoint-stats.sh "$workload_name-memutil" "$workload"

  cpupower frequency-set -g schedutil
  ../utils/pinpoint-stats.sh "$workload_name-schedutil" "$workload"

  ../utils/pinpoint-frequencies.sh "$workload" $(head -1 frequencies.config)
  set +x
done

echo "Restoring frequency governor to: $GOVERNOR"
cpupower frequency-set -g "$GOVERNOR"
