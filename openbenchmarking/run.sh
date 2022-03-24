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
export PRESET_OPTIONS="viennacl.test=1;webp.encode=3;svt-vp9.tune=1;svt-vp9.input=0;mcperf.method=1;mcperf.connections=0;multichase.run-test=0;mbw.run-test=0;mbw.array-size=3;openssl.algo=0;redis.test=0;embree.bin=0;embree.model=0;sysbench.run-test=2"

declare -A TIMES_TO_RUN_OVERRIDE=( ["multichase"]=3)

if [ ! -s "$PROGRESS_FILE" ]; then
    echo "Starting new run"
    # copy all installed tests into test set
    grep -v '^\s*$\|^\s*\#' "$TEST_LIST_FILE" > "$PROGRESS_FILE"
else
    echo "Continuing current run"
fi

TEST_COUNT=$(wc -l < "$PROGRESS_FILE")
for ((i=1;i<=TEST_COUNT;i++)); do
    # take current test from first line
    read -r TEST<"$PROGRESS_FILE"
    echo "Running test $i/$TEST_COUNT: $TEST"

    # Override how often the test should be run
    if [ ${TIMES_TO_RUN_OVERRIDE[$TEST]} ]
    then
        export FORCE_TIMES_TO_RUN=${TIMES_TO_RUN_OVERRIDE[$TEST]}
    else
        export FORCE_TIMES_TO_RUN=1 # Default run just 1 time
    fi

    (cd .. && ./evaluate_benchmarks.sh "utils/workloads/${TEST//\//_}") # / in the test name is replaced with _

    # remove current test (first line)
    sed -i '1d' "$PROGRESS_FILE"
done

rm "$PROGRESS_FILE"
