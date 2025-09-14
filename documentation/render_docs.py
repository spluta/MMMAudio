from glob import glob

if __name__ == "__main__":

    source_directories = ["../mmm_dsp","../mmm_src","../mmm_utils"]

    files = []
    files += [glob(f"{dir}/*.mojo", recursive=True) for dir in source_directories]
    files += [glob(f"{dir}/*.py", recursive=True) for dir in source_directories]
    files = [item for sublist in files for item in sublist]
    
    for file in files:
       print(file)