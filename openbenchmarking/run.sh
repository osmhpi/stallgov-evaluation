#!/usr/bin/env bash

set -e

if [ "$EUID" -ne 0 ]; then 
    echo "Please run this command as root!"
    exit 1
fi

TEST_LIST_FILE="openbenchmarking.tests"

# this file saves the progress in the test set
PROGRESS_FILE="running_tests.lock"

if [ ! -s "$PROGRESS_FILE" ]; then
    echo "Starting new run"
    # copy all installed tests into test set
    grep -v '^\s*$\|^\s*\#' "$TEST_LIST_FILE" > "$PROGRESS_FILE"
    truncate -s -1 "$PROGRESS_FILE" # remove trailing newline
else
    echo "Continuing current run"
fi

TEST_COUNT=$(($(wc -l < "$PROGRESS_FILE")+1)) # add +1 for missing trailing newline
for ((i=1;i<=TEST_COUNT;i++)); do
    # take current test from first line
    read -r TEST<"$PROGRESS_FILE"
    echo "Running test $i/$TEST_COUNT: $TEST"

    (cd .. && ./evaluate_benchmarks.sh "utils/workloads/$TEST")

    # remove current test (first line)
    sed -i '1d' "$PROGRESS_FILE"
done

rm "$PROGRESS_FILE"
