#!/usr/bin/env bash
# Ubuntu / Debian install script

export DEBIAN_FRONTEND=noninteractive
set -e

if [ "$EUID" -ne 0 ]; then 
    echo "Please run this command as root!"
    exit 1
fi

if command -v phoronix-test-suite &> /dev/null
then
    echo "Found Test Suite Installation"
else
    echo "Installing Test Suite"
    if command -v apt &> /dev/null
    then
        TARGET_URL=$(curl -s https://api.github.com/repos/phoronix-test-suite/phoronix-test-suite/releases/latest \
        | grep -o -E "https:\/\/github.com\/phoronix-test-suite\/phoronix-test-suite\/releases\/download\/.*?\/phoronix-test-suite_.*?_all\.deb")

        wget -O phoronix-test-suite.deb $TARGET_URL

        # Required for auto installation of prerequisites
        sudo apt -y install gdebi-core

        sudo gdebi phoronix-test-suite.deb --non-interactive
        rm phoronix-test-suite.deb
    else
        echo "You system does not use APT, please install phoronix-test-suite yourself:"
        echo "https://github.com/phoronix-test-suite/phoronix-test-suite/releases/"
        exit 1
    fi
fi

phoronix-test-suite --version

echo "Configure Test Suite"

phoronix-test-suite user-config-set \
    RemoveDownloadFiles=TRUE \
    SymLinkFilesFromCache=TRUE

echo "Installing Tests"

TEST_LIST_FILE="openbenchmarking.tests"
ROOT_INSTALL_DIRECTORY="/var/lib/phoronix-test-suite"
WORKLOAD_DIRECTORY="../utils/workloads"
mkdir -p "$WORKLOAD_DIRECTORY"

while read -r TEST CONFIG; do
    [ -z $TEST ] && continue

    echo "- Installing $TEST"
    phoronix-test-suite install-dependencies ${TEST}
    phoronix-test-suite batch-install $TEST

    WORKLOAD_FILE="$WORKLOAD_DIRECTORY/$(echo $TEST | sed -e 's/\//_/g')"
    echo -e "#!/usr/bin/env bash\nphoronix-test-suite batch-run $TEST" > "$WORKLOAD_FILE"
    chmod +x "$WORKLOAD_FILE"
    echo "> Created workload script for test suite execution ($WORKLOAD_FILE)"

    # EXEC_SCRIPT=""
    # for PART in $CONFIG; do
    #     [[ $PART == \#* ]] && break
    #     IFS=':' read -r PARAM VALUE <<< "$PART"
    #     case $PARAM in
    #         SCRIPT)
    #             EXEC_SCRIPT=`sed -n -e 's/^.*SCRIPT://p' <<< "$CONFIG"`
    #             ;;
    #         *) # ignore
    #             ;;
    #     esac
    # done

    # if [[ $TEST == system* ]]; then
    #     PATH_SUFFIX="system/"
    #     TEST_NAME=${TEST:7}
    # else
    #     PATH_SUFFIX="pts/"
    #     TEST_NAME=$TEST
    # fi
    # TEST_PATH=`find "$ROOT_INSTALL_DIRECTORY/installed-tests/$PATH_SUFFIX" -maxdepth 1 -name "$TEST_NAME*" -print | sort -V | tail -1`
    # if [ -z $TEST_PATH ]; then
    #     echo "> Test directory not found"
    #     continue
    # fi
    # TEST_EXECUTABLE=`find $TEST_PATH -maxdepth 1 -type f -executable -name "$TEST_NAME*" -print`
    # if [ -z $TEST_PATH ]; then
    #     echo "> Test executable not found"
    #     continue
    # fi

    # WORKLOAD_FILE_DIRECT="$WORKLOAD_FILE-direct"
    # if grep -q "\$TEST_EXTENDS" "$TEST_EXECUTABLE"; then
    #     # has to be run by test suite, idk how to run manually
    #     echo "> Could not create workload script for direct execution (TEST_EXTENDS)"
    #     # echo -e "#!/usr/bin/env bash\n./$WORKLOAD_FILE" > "$WORKLOAD_FILE_DIRECT"
    # else
    #     TEST_SCRIPT_CONTENT="#!/usr/bin/env bash\nset -e\n"

    #     if [[ ! -z $EXEC_SCRIPT ]]; then
    #         TEST_SCRIPT_CONTENT="${TEST_SCRIPT_CONTENT}(cd $TEST_PATH; $EXEC_SCRIPT)"
    #     else
    #         LOG_DIRECTORY="/dev/null"
    #         grep -q "LOG_FILE" "$TEST_EXECUTABLE" && TEST_SCRIPT_CONTENT="${TEST_SCRIPT_CONTENT}export LOG_FILE=$LOG_DIRECTORY\n"
    #         grep -q "NUM_CPU_CORES" "$TEST_EXECUTABLE" && TEST_SCRIPT_CONTENT="${TEST_SCRIPT_CONTENT}export NUM_CPU_CORES=$(nproc)\n"
    #         TEST_EXECUTABLE=`basename $TEST_EXECUTABLE`
    #         TEST_SCRIPT_CONTENT="${TEST_SCRIPT_CONTENT}(cd $TEST_PATH; ./$TEST_EXECUTABLE)"
    #     fi

    #     echo -e "$TEST_SCRIPT_CONTENT" > "$WORKLOAD_FILE_DIRECT"
    #     chmod +x "$WORKLOAD_FILE_DIRECT"
    #     echo "> Created workload script for direct execution ($WORKLOAD_FILE_DIRECT)"
    # fi
    echo ""
done < <(grep -v '^#' $TEST_LIST_FILE)
