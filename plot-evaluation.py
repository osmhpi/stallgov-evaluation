#!/usr/bin/env python3
import matplotlib.pyplot as plt
import argparse
import glob
import re
import os
import sys
from operator import itemgetter

measurements_postfix = "MHz.txt"
decimal_point_char = "."
thousand_char = ","


def parse_frequency(line):
    match = re.match(r"\s*[0-9,.]+\s+cycles\s+#\s+([0-9,.]+) GHz", line)
    if not match:
        raise Exception("Error parsing frequency measurement line. Line is: " + line)
    frequency = match.group(1).replace(thousand_char, "")
    if decimal_point_char != ".":
        frequency = frequency.replace(decimal_point_char, ".")
    return float(frequency)


def parse_energy(line):
    match = re.match(r"\s*([0-9,.]+) Joules energy-pkg\s+#\s+[0-9,.]+ K?/sec\s+\( \+-\s+([0-9,.]+)% \)", line)
    if not match:
        raise Exception("Error parsing energy measurement line. Line is: " + line)
    energy = match.group(1).replace(thousand_char, "")
    deviation = match.group(2).replace(thousand_char, "")
    if decimal_point_char != ".":
        energy = energy.replace(decimal_point_char, ".")
        deviation = deviation.replace(decimal_point_char, ".")
    return float(energy), (float(deviation) * 1e-2)


def parse_time(line):
    match = re.match(r"\s*([0-9,.]+) \+- ([0-9,.]+) seconds time elapsed", line)
    if not match:
        raise Exception("Error parsing time measurement line. Line is: " + line)
    time = match.group(1).replace(thousand_char, "")
    deviation = match.group(2).replace(thousand_char, "")
    if decimal_point_char != ".":
        time = time.replace(decimal_point_char, ".")
        deviation = deviation.replace(decimal_point_char, ".")
    return float(time), float(deviation)


def read_measurement(energy_file_path):
    energy = 0, 0
    frequency = 0
    time = 0
    with open(energy_file_path, "r") as energy_file:
        for line in energy_file:
            if line.find("energy-pkg") != -1:
                energy = parse_energy(line)
            elif line.find("time elapsed") != -1:
                time = parse_time(line)
    frequency_file_path = energy_file_path
    if not os.path.isfile(frequency_file_path):
        raise RuntimeError("Did not find frequency measurement for energy measurement " + energy_file_path)
    with open(frequency_file_path, "r") as frequency_file:
        for line in frequency_file:
            if line.find("cycles") != -1:
                frequency = parse_frequency(line)
    return frequency, energy, time


def read_frequency_measurements(input_folder, workload):
    measurement_files = glob.glob(input_folder + f"/{workload}-*" + measurements_postfix)
    if not measurement_files:
        sys.stderr.write("No frequency measurements found in " + input_folder + os.linesep)
        return []
        # raise RuntimeError("No frequency measurements found in " + input_folder)

    measurements = []
    for file in measurement_files:
        measurements.append(read_measurement(file))
    return measurements


def read_governor_measurements(input_folder, workload):
    measurement_files = ["memutil.txt", "schedutil.txt"]
    measurements = dict()
    for file in measurement_files:
        complete_path = input_folder + "/" + workload + "-" + file
        if not os.path.isfile(complete_path):
            sys.stderr.write("Missing governor measurement " + complete_path + os.linesep)
            # raise RuntimeError("Missing governor measurement " + complete_path)
        else:
            measurements[file[:-4]] = read_measurement(complete_path)
    return measurements


def plot_energy(ax, color, show_deviation, frequencies, energies, times):
    max_energies = list(map(lambda energy: energy[0] + (energy[1] * energy[0]), energies))
    min_energies = list(map(lambda energy: energy[0] - (energy[1] * energy[0]), energies))
    avg_energies = list(map(lambda energy: energy[0], energies))

    if show_deviation:
        ax.fill_between(frequencies, max_energies, min_energies, alpha=0.5, linewidth=0, color=color)

    ax.plot(frequencies, avg_energies, color=color, label="package energy")
    ax.set_ylabel("energy (in Joules)")
    ax.set_ylim(ymin=0)


def plot_time(ax, color, show_deviation, frequencies, energies, times):
    max_times = list(map(lambda time: time[0] + time[1], times))
    min_times = list(map(lambda time: time[0] - time[1], times))
    avg_times = list(map(lambda time: time[0], times))

    if show_deviation:
        ax.fill_between(frequencies, max_times, min_times, alpha=0.5, linewidth=0, color=color)

    ax.plot(frequencies, avg_times, color=color, label="runtime")
    ax.set_ylabel("runtime (in seconds)")
    ax.set_ylim(ymin=0)


def plot_power(ax, color, show_deviation, frequencies, energies, times):
    y_values = list(map(lambda entry: entry[0][0] / entry[1][0], zip(energies, times)))
    ax.plot(frequencies, y_values, color=color, label="power")
    ax.set_ylabel("power (W)")
    ax.set_ylim(ymin=0)


def plot_energy_delay_product(ax, color, show_deviation, frequencies, energies, times):
    y_values = list(map(lambda entry: entry[0][0] * entry[1][0], zip(energies, times)))
    ax.plot(frequencies, y_values, color=color, label="energy delay product")
    ax.set_ylabel("energy delay product (J*s)")
    ax.set_ylim(ymin=0)


parser = argparse.ArgumentParser(description="Plot memory bound util performance data. Use the pinpoint-frequencies "
                                             "script to generate the data for fixed frequencies. Additionally there "
                                             "are expected to exist similar files for the governors / intel_pstate "
                                             "settings active (active.txt, active-freq.txt), passive (passive.txt, "
                                             "passive-freq.txt), disabled (disabled.txt, disabled-freq.txt)")
parser.add_argument("workload", metavar="output", type=str, help="name of the workload to plot")
parser.add_argument("input_folder", metavar="input", type=str, help="path to folder containing all input files")
parser.add_argument("output_file", metavar="output", type=str, help="output image path")
parser.add_argument("--show_deviation", "-sd", action="store_true", default=False, help="Show deviation around plots")
parser.add_argument("--first_plot", "-fp", default="energy", type=str, choices=["energy", "time", "power", "edp",
                                                                                "energy_delay_product"],
                    help="Type of first plot")
parser.add_argument("--second_plot", "-sp", default="none", type=str,
                    choices=["none", "energy", "time", "power", "edp", "energy_delay_product"],
                    help="Type of second plot")
parser.add_argument("--title", "-t", default="Frequency-Energy Plot", type=str, help="Title of figure")
parser.add_argument("--german_float", "-gf", action="store_true", default=False, help="Use german floating point values"
                                                                                      " (i.e. switch usage of , and .)")

args = parser.parse_args()

if args.german_float:
    decimal_point_char, thousand_char = thousand_char, decimal_point_char

plot_map = {"energy": plot_energy, "time": plot_time, "power": plot_power, "edp": plot_energy_delay_product,
            "energy_delay_product": plot_energy_delay_product}

fixed_frequency_measurements = read_frequency_measurements(args.input_folder, args.workload)
governor_measurements = read_governor_measurements(args.input_folder, args.workload)
fixed_frequency_measurements.extend(governor_measurements.values())
fixed_frequency_measurements.sort(key=itemgetter(0))

frequency_energies = list(map(lambda entry: entry[1], fixed_frequency_measurements))
frequency_times = list(map(lambda entry: entry[2], fixed_frequency_measurements))
frequencies = list(map(lambda entry: entry[0], fixed_frequency_measurements))

plt.rcParams.update({'figure.autolayout': True})

colormap = plt.get_cmap("Set1")
fig, ax = plt.subplots()

ax.set_xlabel("frequency (in GHz)")
ax.set_title(args.title)

plot_map[args.first_plot](ax, colormap(0), args.show_deviation, frequencies, frequency_energies, frequency_times)
colormap_offset = 1

additional_lines = []
additional_labels = []
if args.second_plot != "none":
    ax2 = ax.twinx()
    plot_map[args.second_plot](ax2, colormap(1), args.show_deviation, frequencies, frequency_energies, frequency_times)
    additional_lines, additional_labels = ax2.get_legend_handles_labels()
    colormap_offset = 2

for index, governor in enumerate(governor_measurements):
    ax.axvline(governor_measurements[governor][0], linestyle="--", label=governor,
               color=colormap(index+colormap_offset))

lines, labels = ax.get_legend_handles_labels()
ax.legend(additional_lines + lines, additional_labels + labels)
fig.savefig(args.output_file)
'''
    data.iloc[:, 0:-args.powerColumnsCount].plot.line(ax=axes, colormap="Set1")
    axes.set_xlabel("time (ms)")
    axes.set_ylabel("Frequency (MHz)")
    axes2 = axes.twinx()
    data.iloc[:, -args.powerColumnsCount:].plot.line(ax=axes2, style="--", colormap="Pastel1")
    axes2.set_ylabel("Power (mW)")

fig.savefig(args.outputFile)
'''
