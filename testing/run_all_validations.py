from glob import glob
import os
import argparse

parser = argparse.ArgumentParser()
parser.add_argument("--show-plots", action="store_true", help="Display plots for each validation script")
args = parser.parse_args()

validations = glob("testing/*_Validation.py")

for validation in validations:
    print(f"Running {validation}...")
    command = f"python3 {validation}"
    if args.show_plots:
        command += " --show-plots"
    os.system(command)
    print(f"Completed {validation}\n")