#!/usr/bin/env bash

if [ -z $PERF ]; then
    PERF=perf
fi

TARGET_ENERGY_EVENTS="energy-pkg energy-cores energy-gpu energy-ram"
TRACKED_ENERGY_EVENTS=""
echo "Scanning energy events:"
AVAILABLE_EVENTS=$($PERF list --no-desc pmu)
for EVENT in $TARGET_ENERGY_EVENTS; do
    if echo "$AVAILABLE_EVENTS" | grep -q "$EVENT"; then
        echo -e "- $EVENT:\tavailable"
        TRACKED_ENERGY_EVENTS="$TRACKED_ENERGY_EVENTS $EVENT"
    else
        echo -e "- $EVENT:\tnot available"
    fi
done
export TRACKED_ENERGY_EVENTS="$TRACKED_ENERGY_EVENTS"

if [ -z $CPUPOWER ]
then
    CPUPOWER=cpupower
fi

if [ "$EUID" -ne 0 ]; then
    echo "Please run this command as root!"
    exit 1
fi

if [ -z $OUTPUT_DIRECTORY ]; then
    OUTPUT_DIRECTORY="."
fi


GOVERNOR=$($CPUPOWER frequency-info -p | awk '/^.+The governor/ { gsub(/"/,""); print $3 }')
$CPUPOWER frequency-set -g performance
OLD_MAX_FREQ=$($CPUPOWER frequency-info -p | awk '/^.+current policy:/ { gsub(/\.$/,""); print $10$11 }')

WORKLOAD="$1"
WORKLOAD_NAME=$(basename "$WORKLOAD")

SCRIPTDIR=$(dirname $(readlink -f "$0"))

set -ex

# Iterate over all arguments, but the first
for argument in "${@:2:$#}"
do
    $CPUPOWER frequency-set --max "$argument" && echo "CPU Frequency set to: " "$argument"
    $SCRIPTDIR/pinpoint-stats.sh "$WORKLOAD_NAME-$argument" "$WORKLOAD"
done

echo "Returning to old governor $GOVERNOR"
$CPUPOWER frequency-set -g "$GOVERNOR"
echo "Returning to old maximum frequency $OLD_MAX_FREQ"
$CPUPOWER frequency-set --max "$OLD_MAX_FREQ"
