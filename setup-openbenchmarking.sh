#!/usr/bin/env bash
Ubuntu / Debian install script

export DEBIAN_FRONTEND=noninteractive

TARGET_URL=$(curl -s https://api.github.com/repos/phoronix-test-suite/phoronix-test-suite/releases/latest \
| grep -o -E "https:\/\/github.com\/phoronix-test-suite\/phoronix-test-suite\/releases\/download\/.*?\/phoronix-test-suite_.*?_all\.deb")

wget -O phoronix-test-suite.deb $TARGET_URL

# Required for auto installation of prerequisites
sudo apt -y install gdebi-core

sudo gdebi phoronix-test-suite.deb --non-interactive
rm phoronix-test-suite.deb

phoronix-test-suite --version

TEST_LIST_FILE="openbenchmarking.tests"
TESTS=""
while read -r testname comment; do
    TESTS="${TESTS} ${testname}"
done < <(grep -v '^#' $TEST_LIST_FILE)

for TEST in ${TESTS}; do
    echo "installing ${TEST}"
    phoronix-test-suite install-dependencies ${TEST}
    phoronix-test-suite install ${TEST}
done
