from glob import glob
import os
import subprocess

def test_dir_of_pys(dirpath: str):
    python_files = glob(f"{dirpath}/*.py")
    for py_file in python_files:
        if os.path.basename(py_file) != "__init__.py":
            print(f"Running {py_file}...")
            subprocess.run(["python", py_file], check=True)
            
if __name__ == "__main__":
    test_dir_of_pys("testing_mmm_audio/py_unit_tests")