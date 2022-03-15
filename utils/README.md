# Prerequirements

- cmake/cpp compiler
- rust/cargo
- perf/cpupower

# Execution 
In the end, we need to produce the following files:
- active.txt - Intel Pstate driver active
- passive.txt - Intel PState driver in passive mode
- schedutil.txt - Schedutil frequency governor
- XXXXMHz.txt - A file for every fixed frequency run

## Intel PState active
Confirm your intel pstate driver is active by running:
`cpupower frequency-info`

The output should look like this:
```
analyzing CPU 0:
  driver: intel_pstate
  CPUs which run at the same hardware frequency: 0
  CPUs which need to have their frequency coordinated by software: 0
  maximum transition latency:  Cannot determine or is not supported.
  hardware limits: 800 MHz - 4.20 GHz
  available cpufreq governors: performance powersave
  current policy: frequency should be within 800 MHz and 4.20 GHz.
                  The governor "powersave" may decide which speed to use
                  within this range.
  current CPU frequency: Unable to call hardware
  current CPU frequency: 1.20 GHz (asserted by call to kernel)
  boost state support:
    Supported: yes
    Active: yes
```
The driver: needs to be `intel_pstate`. If the driver is `intel_cpufreq`, `intel_pstate` is only available in passive mode.

If Intel PState is enabled, run the following commands:
```bash
./pinpoint-stats "active" "./workload-pointer-chasing"
```

If you want to run the primes (CPU bound) benchmark instead, replace `./workload-pointer-chasing` with `./workload-primes`.

## Intel PState passive
To put your intel pstate driver in passive mode, reboot and provide `intel_pstate=passive` as a kernel parameter through the GRUB boot menu.

Then run:
```bash
./pinpoint-stats "passive" "./workload-pointer-chasing"
```

Replace the memory-bound executable with another benchmark if apropriate.

## SchedUtil
To be able to use the default Linux CpuFreq governors, reboot and provide `intel_pstate=disable` as a kernel parameter through the GRUB boot menu.

Then confirm that SchedUtil is active, by running `cpupower frequency-info`:
```
analyzing CPU 0:
  driver: acpi-cpufreq
  CPUs which run at the same hardware frequency: 0
  CPUs which need to have their frequency coordinated by software: 0
  maximum transition latency: 10.0 us
  hardware limits: 1.20 GHz - 2.10 GHz
  available frequency steps:  2.10 GHz, 2.10 GHz, 2.00 GHz, 1.90 GHz, 1.80 GHz, 1.70 GHz, 1.60 GHz, 1.50 GHz, 1.40 GHz, 1.30 GHz, 1.20 GHz
  available cpufreq governors: conservative ondemand userspace powersave performance schedutil
  current policy: frequency should be within 1.20 GHz and 2.10 GHz.
                  The governor "schedutil" may decide which speed to use
                  within this range.
  current CPU frequency: Unable to call hardware
  current CPU frequency: 2.09 GHz (asserted by call to kernel)
  boost state support:
    Supported: yes
    Active: yes
    25500 MHz max turbo 4 active cores
    25500 MHz max turbo 3 active cores
    25500 MHz max turbo 2 active cores
    25500 MHz max turbo 1 active cores
```
The important parts here are the `driver`, which must be acpi-cpufreq and the `current policy`, which lists the currently active governor.

If the governor is not SchedUtil (i.e. `ondemand`), use `cpupower frequency-set -g schedutil` to change it.

Then run:
```bash
./pinpoint-stats "schedutil" "./workload-pointer-chasing"
```

Replace the memory-bound executable with another benchmark if apropriate.

## Locked frequencies
First, make sure the Intel PState driver is disabled (see SchedUtil section).

Use `cpupower frequency-info` to get the available frequency steps.

Then run:
```bash
./pinpoint-frequencies-<workload name> XXXMHz XXXMHz XXXMHz ...
```

For `<workload name>` use either `pointer-chasing` for the memory-bound workload, or `primes` for CPU bound benchmark.

Replacing XXXMHz with the available frequency steps (e.g. 2100MHz for 2.10 GHz).
This will then generate a file for each frequency step.

# Plotting

```
python3 plot.py <input folder> <output .png> -sp time -sd
```

If your perf run produces output in German number formatting (period and comma swapped), add the `-gf` option.
