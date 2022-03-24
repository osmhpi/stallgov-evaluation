#!/usr/bin/env bash

set -e

if [ "$EUID" -ne 0 ]; then 
    echo "Please run this command as root!"
    exit 1
fi

echo "Configure Test Suite"

phoronix-test-suite user-config-set \
    AnonymousUsageReporting=TRUE \
    AlwaysUploadSystemLogs=FALSE \
    AllowResultUploadsToOpenBenchmarking=FALSE \
    AnonymousUsageReporting=NoInternetCommunication \
    AnonymousUsageReporting=NoNetworkCommunication \
    \
    UsePhodeviCache=TRUE \
    ShowPostRunStatistics=TRUE \
    DynamicRunCount=FALSE \
    DefaultDisplayMode=BATCH \
    \
    SaveResults=TRUE \
    OpenBrowser=FALSE \
    UploadResults=FALSE \
    PromptForTestIdentifier=FALSE \
    PromptForTestDescription=FALSE \
    PromptSaveName=FALSE \
    RunAllTestCombinations=FALSE


TEST_LIST_FILE="openbenchmarking.tests"

# this file saves the progress in the test set
PROGRESS_FILE="running_tests.lock"

export TEST_RUNS=3 # configures re-executes by perf
export FORCE_TIMES_TO_RUN=1 # configures re-runs of benchmark suite (can be overwritten in openbenchmarkings.tests)

if [ ! -s "$PROGRESS_FILE" ]; then
    echo "Starting new run"
    # copy all installed tests into test set
    grep -v '^\s*$\|^\s*\#' "$TEST_LIST_FILE" > "$PROGRESS_FILE"
else
    echo "Continuing current run"
fi

WORKLOAD_PATH="utils/workloads"

TEST_COUNT=$(wc -l < "$PROGRESS_FILE")
for ((i=1;i<=TEST_COUNT;i++)); do
    # take current test from first line
    read -r TEST CONFIG<"$PROGRESS_FILE"
    echo "Running test $i/$TEST_COUNT: $TEST"

    for PART in $CONFIG; do
        [[ $PART == \#* ]] && break
        IFS=':' read -r TARGET_ENV_VAR VALUE <<< "$PART"
        echo "with $TARGET_ENV_VAR=$VALUE"
        export $TARGET_ENV_VAR="$VALUE"
    done

    WORKLOAD_SCRIPT="$WORKLOAD_PATH/${TEST//\//_}" # / in the test name is replaced with _
    if [ -f "../$WORKLOAD_SCRIPT-direct" ]; then
        WORKLOAD_SCRIPT="$WORKLOAD_SCRIPT-direct"
    fi
    echo $WORKLOAD_SCRIPT

    (cd .. && ./evaluate_benchmarks.sh "$WORKLOAD_SCRIPT") 

    echo ""
    # remove current test (first line)
    sed -i '1d' "$PROGRESS_FILE"
done

rm "$PROGRESS_FILE"
