#!/usr/bin/env bash

BENCH_RUN_FOLDER=""
WORKLOAD_NAMES=""
OUTPUT_FILE="output.png"
NUMBER_FORMAT_PARAM=""

POSITIONAL=()
while [[ $# -gt 0 ]]; do
	case "$1" in
		--number_format)
            case "$2" in
                EN)
                    NUMBER_FORMAT_PARAM=""
                    ;;
                DE)
                    NUMBER_FORMAT_PARAM="-gf"
                    ;;
                *)
                    echo "invalid number format - possible values: EN, DE"
                    exit 1
                    ;;
            esac
			shift # past argument
			shift # past value
			;;
		--help)
			echo "./plot.sh <bench_run_folder> [workload_names...] [--number_format EN/DE]"
			echo "Default number format is EN"
			exit 0
			;;
		*) # unknown option
			POSITIONAL+=("$1") # save it in an array for later
			shift # past argument
			;;
	esac
done
set -- "${POSITIONAL[@]}" # restore positional parameters

if [ "$#" -le "0" ]; then
    echo "./plot.sh <bench_run_folder> [workload_names...] [--number_format EN/DE]"
    echo "Default number format is EN"
    exit 1
fi

BENCH_RUN_FOLDER="$1"
if [ "$#" -gt 1 ]; then
    WORKLOAD_NAMES="${@:2:$#}"
else
    for POSSIBLE_WORKLOAD in `ls $BENCH_RUN_FOLDER`; do
        if [ -f "$BENCH_RUN_FOLDER/$POSSIBLE_WORKLOAD/$POSSIBLE_WORKLOAD-memutil.txt" ] \
        && [ -f "$BENCH_RUN_FOLDER/$POSSIBLE_WORKLOAD/$POSSIBLE_WORKLOAD-schedutil.txt" ]; then
            WORKLOAD_NAMES="$WORKLOAD_NAMES $POSSIBLE_WORKLOAD"
        fi
    done
fi

for WORKLOAD_NAME in $WORKLOAD_NAMES; do
    TEST_RUN_FOLDER="$BENCH_RUN_FOLDER/$WORKLOAD_NAME"
    echo "Plotting $TEST_RUN_FOLDER"
    python plot-evaluation.py -sd -sp time $NUMBER_FORMAT_PARAM "$WORKLOAD_NAME" "$TEST_RUN_FOLDER" "$TEST_RUN_FOLDER/$OUTPUT_FILE"
done
