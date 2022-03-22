# OpenBenchmarking via Phoronix Test Suite

https://openbenchmarking.org/
https://phoronix-test-suite.com/

This test suite contains multiple tests from openbenchmarking.org which are selected to test the performance and characteristics of Memutil in different scenarios. Some of them are specifically targeted towards memory operations, while others are more generic to cover int/float math, raytracing, compression or cryptography. There are also real-world representations for databases, codecs and build systems.

## Setup

Use `setup.sh` to install the Phoronix Test Suite and its dependencies via APT. If your system uses another package manager, please use https://github.com/phoronix-test-suite/phoronix-test-suite/releases/ to download the current package.

Furthermore, the setup script installs the given tests listed in `openbenchmarking.tests` and creates run scripts for each of them in `../utils/workloads/`. If test dependencies are not installed correctly, you can comment in `setup.sh:41` or use this line to install missing dependencies yourself.

To complete the setup, run `phoronix-test-suite batch-setup` to prepare the Phoronix Test Suite for batch mode.
Recommended settings are (you don't have to upload your results):
```
Save test results when in batch mode (Y/n): Y
Open the web browser automatically when in batch mode (y/N): N
Auto upload the results to OpenBenchmarking.org (Y/n): Y
Prompt for test identifier (Y/n): n
Prompt for test description (Y/n): n
Prompt for saved results file-name (Y/n): n
Run all test options (Y/n): Y
```
It is important to deny prompts, because they are not handled by our run script. Also, `run all test options` is needed for some tests, because they ask to select a run configuration.

## Running

To start a new test suite run, use `run.sh`. This will create a lock file which contains all remaining tests to be executed and will be updated after each test, so that you can interrupt this at any time and continue later. This script executes `../evaluate_benchmarks.sh` for each test with the matching workload script from `../utils/workloads`, which itself calls the Phoronix Test Suite batch-run.

Output will be written to `../results/new` by default, but can be configured using the environment variable `BENCHMARK_OUTPUT_DIRECTORY`.

Each test will run for each frequency, defined by `../frequencies.config`.

Because the test suite already runs test multiple times themselves, the environment variable `TEST_RUNS` is set to 1 by default.