#!/usr/bin/env python3

import multiprocessing
import matplotlib.pyplot as plt
import matplotlib.cbook as cbook
import pandas
import numpy
import argparse

def custom_divide(a, b):
    if b == 0:
        return 0 if a == 0 else -2
    return float(a) / float(b)
vcustom_divide = numpy.vectorize(custom_divide) # this is not performant

def plot_div(time_data, data, add_label, plot_names, numerator, denominator, color):
    label = plot_names[0] if add_label else ""
    ydata = vcustom_divide(data[numerator], data[denominator])
    plt.plot(time_data, ydata, label=label, color=color)


def plot_add_div(time_data, data, add_label, plot_names):
    label = plot_names[0] if add_label else ""
    ydata = vcustom_divide(data['value1'] + data['value2'], data['value3'])
    colormap = plt.get_cmap("Set1")
    plt.plot(time_data, ydata, label=label, color=colormap(0))


def plot_div_1_2(time_data, data, add_label, plot_names):
    colormap = plt.get_cmap("Set1")
    plot_div(time_data, data, add_label, plot_names, "value1", "value2", colormap(0))


def plot_div_2_3(time_data, data, add_label, plot_names):
    colormap = plt.get_cmap("Set1")
    plot_div(time_data, data, add_label, plot_names, "value2", "value3", colormap(0))


def plot_div_1_3_div_2_3(time_data, data, add_label, plot_names):
    if len(plot_names) < 2:
        plot_names = ['1/3', '2/3']
    colormap = plt.get_cmap("Set1")
    plot_div(time_data, data, add_label, plot_names[0:1], "value1", "value3", colormap(0))
    plot_div(time_data, data, add_label, plot_names[1:2], "value2", "value3", colormap(1))


def plot_div_1_add_1_2(time_data, data, add_label, plot_names):
    label = plot_names[0] if add_label else ""
    ydata = vcustom_divide(data["value1"], data["value1"] + data["value2"])
    colormap = plt.get_cmap("Set1")
    plt.plot(time_data, ydata, label=label, color=colormap(0))


plot_methods = {"div_1_2": plot_div_1_2, "div_2_3": plot_div_2_3, "add_div": plot_add_div, "div_1_3+div_2_3": plot_div_1_3_div_2_3, "div_1_(1+2)": plot_div_1_add_1_2}

parser = argparse.ArgumentParser(description="Plot the data generated by copy-log.sh")
parser.add_argument("input_folder", metavar="input", type=str, help="path to folder containing the log files")
parser.add_argument("output_file", metavar="output", nargs='?', type=str, default='', help="output image path - plot will be displayed if output is left empty")
parser.add_argument("--title", "-t", default="Perfcounter Plot", type=str, help="Title of figure")
parser.add_argument("--cores", "-c",
                    default=','.join(map(str,numpy.arange(0, multiprocessing.cpu_count()))),
                    type=str,
                    help="Comma separated list of cores to plot (all by default)")
parser.add_argument("--plot_op", "-p", type=str, default="div_1_2", choices=plot_methods.keys(), help="What method should be used for plotting")
parser.add_argument("--scale", "-s", type=float, default=1.0, help="Scale the plot should have.")
parser.add_argument("--plot_names", type=str, nargs='+', default=[], help="Names to use for the plots")

args = parser.parse_args()

plt.rcParams.update({'figure.autolayout': True})

cpus = [int(item) for item in args.cores.split(',')]

for i in cpus:
    data = numpy.genfromtxt(f"{args.input_folder}/log-{i}.txt", delimiter=',', names=['CPU','Time','value1', 'value2', 'value3'])
    time_data = (data['Time'] - data['Time'][0]) / 1e9
    plot_methods[args.plot_op](time_data, data, i == cpus[0], args.plot_names)

plt.xlabel("time (in seconds)")
plt.title(args.title)
plt.legend()
plt.gcf().set_size_inches(6.4*args.scale, 4.8*args.scale)


if args.output_file:
    plt.savefig(args.output_file, dpi=300)
else:
    plt.show()