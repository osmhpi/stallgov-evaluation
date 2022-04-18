#!/usr/bin/env python3

import argparse
import subprocess
import pathlib
import math
import time

parser = argparse.ArgumentParser(description="Evaluate multiple performance counters for multiple workloads",
                                 formatter_class=argparse.ArgumentDefaultsHelpFormatter)
parser.add_argument("--cores", "-c", type=str, nargs="?", default="", help="Core list for plot-log.py")
parser.add_argument("--replot", "-r", action="store_true", help="Just redo the plotting")
parser.add_argument("--scale", "-s", type=float, default=1.0, help="Scale for plotting")

args = parser.parse_args()

counters = [{'counter': ['cycle_activity.cycles_l1d_miss', 'cycle_activity.stalls_l1d_miss', 'cpu_clk_unhalted.thread'], 'title': 'L1_Pend_Stall_Cycles', 'plot_op': 'div_1_3+div_2_3', 'plot_names': ['Pending', 'Stalls']},
            {'counter': ['cycle_activity.cycles_l2_miss', 'cycle_activity.stalls_l2_miss', 'cpu_clk_unhalted.thread'], 'title': 'L2_Pend_Stall_Cycles', 'plot_op': 'div_1_3+div_2_3', 'plot_names': ['Pending', 'Stalls']},
            {'counter': ['cycle_activity.cycles_l3_miss', 'cycle_activity.stalls_l3_miss', 'cpu_clk_unhalted.thread'], 'title': 'L3_Pend_Stall_Cycles', 'plot_op': 'div_1_3+div_2_3', 'plot_names': ['Pending', 'Stalls']},
            {'counter': ['mem_load_retired.l1_hit', 'mem_load_retired.l1_miss', 'cpu_clk_unhalted.thread'], 'title': 'L1_Hitrate', 'plot_op': 'div_1_(1+2)', 'plot_names': ['Hitrate']},
            {'counter': ['mem_load_retired.l2_hit', 'mem_load_retired.l2_miss', 'cpu_clk_unhalted.thread'], 'title': 'L2_Hitrate', 'plot_op': 'div_1_(1+2)', 'plot_names': ['Hitrate']},
            {'counter': ['mem_load_retired.l3_hit', 'mem_load_retired.l3_miss', 'cpu_clk_unhalted.thread'], 'title': 'L3_Hitrate', 'plot_op': 'div_1_(1+2)', 'plot_names': ['Hitrate']},
            {'counter': ['uops_executed.stall_cycles', 'cycle_activity.stalls_mem_any', 'cpu_clk_unhalted.thread'], 'title': 'U_Execute-Stall_vs_Mem-Stall', 'plot_op': 'div_1_3+div_2_3', 'plot_names': ['Execute Stalls', 'Mem Stalls']},
            {'counter': ['uops_retired.stall_cycles', 'cycle_activity.stalls_mem_any', 'cpu_clk_unhalted.thread'], 'title': 'U_Retired-Stall_vs_Mem-Stall', 'plot_op': 'div_1_3+div_2_3', 'plot_names': ['Retired Stalls', 'Mem Stalls']},
            {'counter': ['uops_issued.stall_cycles', 'cycle_activity.stalls_mem_any', 'cpu_clk_unhalted.thread'], 'title': 'U_Issued-Stall_vs_Mem-Stall', 'plot_op': 'div_1_3+div_2_3', 'plot_names': ['Issued Stalls', 'Mem Stalls']},
            {'counter': ['resource_stalls.any', 'cycle_activity.stalls_mem_any', 'cpu_clk_unhalted.thread'], 'title': 'U_Resource-Stall_vs_Mem-Stall', 'plot_op': 'div_1_3+div_2_3', 'plot_names': ['Resource Stalls', 'Mem Stalls']},
            {'counter': ['cycle_activity.stalls_total', 'cycle_activity.stalls_mem_any', 'cpu_clk_unhalted.thread'], 'title': 'Stall_Total_vs_Mem-Stall', 'plot_op': 'div_1_3+div_2_3', 'plot_names': ['Stalls Total', 'Mem Stalls']},
            {'counter': ['arith.divider_active', 'inst_retired.any', 'cpu_clk_unhalted.thread'], 'title': 'Divider cycles vs IPC', 'plot_op': 'div_1_3+div_2_3', 'plot_names': ['Divider Cycles', 'IPC']}]

workloads = ['../../utils/NPB-CPP/NPB-OMP/bin/is.C', '../../utils/NPB-CPP/NPB-OMP/bin/ep.B',
             '../../utils/NPB-CPP/NPB-OMP/bin/cg.B', '../../utils/NPB-CPP/NPB-OMP/bin/mg.C',
             '../../utils/NPB-CPP/NPB-OMP/bin/ft.B']


def load_memutil(counter):
    subprocess.run(['./load_memutil.sh', counter[0], counter[1], counter[2]], check=True)


def unload_memutil():
    subprocess.run(['./unload_memutil.sh'], check=True)


def benchmark_workloads():
    for file in pathlib.Path.cwd().glob("*-memutil-log"):
        raise Exception(f"Existing memutil log found: {file}.\nNo logs may exist prior to benchmarking")
    args = ['./evaluate_perf_counters.sh']
    args.extend(workloads)
    subprocess.run(args, check=True)


def move_benchmark_results(folder_name):
    benchmark_root = pathlib.Path(folder_name)
    benchmark_root.mkdir()
    for file in pathlib.Path.cwd().glob('*-memutil-log'):
        file.rename(benchmark_root / file.name)


def plot_results(title, plot_op, folder_name, plot_names, cores_argument, scale):
    img_paths = []
    for file in pathlib.Path(folder_name).glob('*-memutil-log'):
        base_name = str(file).removesuffix("-memutil-log")
        img_path = base_name + ".png"
        workload_name = base_name.removeprefix(folder_name + "/")
        plot_arguments = ["plot-log.py", "-t", workload_name + ": " + title, "-s", str(scale), '--plot_names']
        plot_arguments.extend(plot_names)
        if cores_argument:
            plot_arguments.append("-c")
            plot_arguments.append(cores_argument)
        plot_arguments.extend(["-p", plot_op, file, img_path])
        print("Plotting %s..." % img_path)
        subprocess.run(plot_arguments, check=True)
        img_paths.append(img_path)
    tile_size = int(math.ceil(math.sqrt(len(img_paths))))
    complete_file = folder_name + "/complete.png"
    pathlib.Path(complete_file).unlink(missing_ok=True)
    print("Creating montage %s..." % complete_file)
    subprocess.run(
        ["gm", "montage", "-mode", "concatenate", "-tile", str(tile_size) + "x", folder_name + "/*.png", complete_file],
        check=True)


for entry in counters:
    if not args.replot:
        load_memutil(entry['counter'])
        benchmark_workloads()
        unload_memutil()
        move_benchmark_results(entry['title'])
        time.sleep(60)
    plot_results(entry['title'], entry['plot_op'], entry['title'], entry['plot_names'], args.cores, args.scale)
