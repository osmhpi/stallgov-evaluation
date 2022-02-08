# Evaluation

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
./evaluate_benchmarks.sh ../utils/workload-primes ../utils/workload-pointer-chasing
```

### Output
./evaluate_benchmarks.sh will generate a `.txt` file containing perf energy data for all frequencies & governors tested.
It will also copy the memutil log for every workload into a `<workload>-memutil-log` directory using the ../kernel-module/copy-log.sh script.

The ./plot-evaluation.py script can be used to generate image files with the energy plots for each workload.

You can also plot the memutil workload log using the `plot-log.sh` in the `utils` directory.

