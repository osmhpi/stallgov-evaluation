#!/usr/bin/env bash

if [ "$#" -ne 2 ]; then
    echo "Illegal number of parameters. Expected: 2 arguments [file name] [command to execute]"
    exit 1
fi

if [ "$EUID" -ne 0 ]; then
    echo "Please run this command as root!"
    exit 1
fi

if [ -z $PERF ]; then
    PERF=perf
fi

if [ -z $OUTPUT_DIRECTORY ]; then
    OUTPUT_DIRECTORY="."
fi

PERF_ENERGY_EVENT_PARAMS=""
if [ -z $TRACKED_ENERGY_EVENTS ]; then
    PERF_ENERGY_EVENT_PARAMS="-e energy-pkg"
else
    for EVENT in $TRACKED_ENERGY_EVENTS; do
        PERF_ENERGY_EVENT_PARAMS="$PERF_ENERGY_EVENT_PARAMS -e $EVENT"
    done
fi

set -x
set -e

# The --all-cpus option is necessary, as otherwise the rapl energy counters are not supported by perf for some reason.
# In that case it would be necessary to run perf twice, once for energy counters and once for performance counter meeasurement
$PERF stat $PERF_ENERGY_EVENT_PARAMS -e cycles -e task-clock --all-cpus -o "$OUTPUT_DIRECTORY/$1.txt" -r 3 $2
