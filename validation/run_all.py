from glob import glob
import argparse
import os


def parse_args():
    parser = argparse.ArgumentParser(description="Run all validation scripts.")
    parser.add_argument(
        "--show-plots",
        action="store_true",
        help="Display plots interactively (pauses execution).",
    )
    return parser.parse_args()


args = parse_args()

validations = glob("validation/*_Validation.py")

show_arg = "--show-plots" if args.show_plots else ""

for validation in validations:
    print(f"Running {validation}...")
    os.system(f"python3 {validation} {show_arg}".strip())
    print(f"Completed {validation}\n")