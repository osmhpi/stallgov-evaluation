#!/usr/bin/env bash
# Ubuntu / Debian install script

export DEBIAN_FRONTEND=noninteractive
set -e

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
fi

phoronix-test-suite --version

echo "Installing Tests"

TEST_LIST_FILE="openbenchmarking.tests"
TESTS=""
while read -r testname comment; do
    TESTS="$TESTS $testname"
done < <(grep -v '^#' $TEST_LIST_FILE)

echo "Installing Test Scripts"

WORKLOAD_DIRECTORY="../utils/workloads"
mkdir -p "$WORKLOAD_DIRECTORY"
for TEST in $TESTS; do
    echo "installing $TEST"
    phoronix-test-suite install-dependencies ${TEST}
    phoronix-test-suite batch-install $TEST
    workload_file="$WORKLOAD_DIRECTORY/$(echo $TEST | sed -e 's/\//_/g')"
    echo -e "#!/usr/bin/env bash\nphoronix-test-suite batch-run $TEST" > "$workload_file"
    chmod +x "$workload_file"
done
