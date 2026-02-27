from glob import glob
import os
from pathlib import Path
import subprocess

def test_dir(dirpath: str):
    mojo_files = glob(f"{dirpath}/*.mojo")
    for mojo_file in mojo_files:
        if os.path.basename(mojo_file) != "__init__.mojo":
            print(f"Running {mojo_file}...")
            subprocess.run(["mojo", "build", "--emit", "object", mojo_file], check=True)
            stem = Path(mojo_file).stem
            os.system(f"rm {stem}.o")
            
if __name__ == "__main__":
    test_dir("mmm_audio")
    test_dir("examples")
    test_dir("examples/tests")