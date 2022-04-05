# Evaluation

This folder contains utilities and workloads for evaluating the performance of memutil.
It also contains the results of our own evaluations in the `results` folder.

The evaluations were performed on the following machines:
- Leon - Laptop
  - Gigabyte Aero 14
  - i7 6700HQ
  - 16GB RAM DDR4
  - Fedora 34 - KDE Spin
- Erik - Intel
  - Dell XPS 13-7390
  - i7-10510U
  - 16GB RAM DDR4
  - Ubuntu 21.10
- Erik - AMD
  - Ryzen 9 5900X
  - 32GB RAM DDR4
  - Ubuntu 21.10
- Max - AMD
  - Ryzen 5 3600X
  - 64GB RAM DDR4
  - Ubuntu / Kernel 5.17.0-rc2

The `openbenchmarking` folder contains scripts to set up and run the phoronix test suite.

The `utils` folder contains utility scripts for running&measuring workloads, as well as plotting and analyzing different results.

This folder only contains the higher-level scripts that can be used to evaluate multiple workloads at once.

## ./evaluate_benchmarks.sh

The purpose of this script is to run a list of workloads on the schedutil and memutil CpuFreq Governors, as well as a list of predefined frequencies.

This way, an ideal frequency for a specific workload can be estimated, as well as how well schedutil and memutil performed on this workload.

### Setup
The script needs to know which frequencies are available for testing.
To get a list of available frequencies run `cpupower frequency-info` and look at the "available frequency steps" section.

Then create a `frequencies.config` file.
This file must contain a single line with all frequencies you want to test listed, separated by space.
Look at  the `frequencies.config.example` file to see how to format the frequency.

### Usage
./evaluate_benchmarks.sh takes a list of workloads to execute as arguments.

Example:
``` bash
./evaluate_benchmarks.sh utils/workload-primes utils/workload-pointer-chasing
```

### Output
./evaluate_benchmarks.sh will generate a `.txt` file containing perf energy data for all frequencies & governors tested.
It will also copy the memutil log for every workload into a `<workload>-memutil-log` directory using the ../kernel-module/copy-log.sh script.

The ./plot-evaluation.py script can be used to generate image files with the energy plots for each workload.

You can also plot the memutil workload log using the `plot-log.sh` in the `utils` directory.

## evalute_perf_counters.sh
This script will run the provided workloads three times and store the memutil log for all of them.

This is specifically useful to evaluate different performance counters used by memutil.
It can i.e. be used in conjunction with the event_name1-3 module parameters to quickly change between and evaluate different performance counters.

## plot-evaluation.py
This script plots the result of an evaluation run performed by `evaluate_benchmarks.sh` for a single workload.
See the `--help` option for usage details.

## plot-multiple.sh
Runs plot-evaluation.py for multiple workloads and stitches the resulting image files together into one combined image containing multiple graphs.
Note that if the numbers of the output files are in german format (see plot-evaluation help) this script does not account for that. You would need to
manually add "-gf" to the call in this script.
