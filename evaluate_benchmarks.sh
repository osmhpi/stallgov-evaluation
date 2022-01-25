#!/bin/env bash

set -e

if [[ ! -f "frequencies.config" ]]; then
  echo "Error: frequencies.config does not exist!"
  echo "frequencies.config must be a file with all frequencies"
  echo "to evaluate on the first line (separated by space)"
  echo "See frequencies.config.example for an example file."
  echo ""
  echo "You can get access to all available frequencies with:"
  echo "        $CPUPOWER frequency-info"
  exit 1
fi

if [ "$EUID" -ne 0 ]; then 
    echo "Please run this command as root!"
    exit 1
fi

if [ -z $CPUPOWER ]; then
    CPUPOWER=cpupower
fi

GOVERNOR=$($CPUPOWER frequency-info -p | awk '/^.+The governor/ { gsub(/"/,""); print $3 }')

for workload in "$@"
do
  echo "####### Running workload ${workload} ##########"

  workload_name=$(basename "$workload")
  set -x


  $CPUPOWER frequency-set -g memutil
  mkdir -p "$workload_name-memutil-log"
  # Copying the current log will clear it, so we start with a fresh log
  cp /sys/kernel/debug/memutil/log /dev/null
  # Start the copy-log, as well as pinpoint-stats commands in the background
  # and terminate both, if one of them exits.
  # See: https://unix.stackexchange.com/questions/231676/given-two-background-commands-terminate-the-remaining-one-when-either-exits
  ../kernel-module/copy-log.sh -c -i 8 "$workload_name-memutil-log" $(nproc) &
  # Start logging a short period before running the workload
  sleep 0.1s
  ../utils/pinpoint-stats.sh "$workload_name-memutil" "$workload" &
  wait -n
  pkill -P $$
  wait -n # Wait to assure all logs have been copied

  $CPUPOWER frequency-set -g schedutil
  ../utils/pinpoint-stats.sh "$workload_name-schedutil" "$workload"

  ../utils/pinpoint-frequencies.sh "$workload" $(head -1 frequencies.config)
  set +x
done

echo "Restoring frequency governor to: $GOVERNOR"
$CPUPOWER frequency-set -g "$GOVERNOR"
