from glob import glob
import os

validations = glob("validation/*_Validation.py")

for validation in validations:
    print(f"Running {validation}...")
    os.system(f"python3 {validation}")
    print(f"Completed {validation}\n")