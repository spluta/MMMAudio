from glob import glob
import os
import argparse
import subprocess

parser = argparse.ArgumentParser()
parser.add_argument("--show-plots", action="store_true", help="Display plots for each validation script")
args = parser.parse_args()

validations = glob("testing_mmm_audio/validation/*_Validation.py")

for validation in validations:
    print(f"Running {validation}...")
    cmd = ["python3", validation]
    if args.show_plots:
        cmd.append("--show-plots")
    subprocess.run(cmd, check=True)
    print(f"Completed {validation}\n")