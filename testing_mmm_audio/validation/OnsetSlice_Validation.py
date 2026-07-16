import os
import csv
import matplotlib.pyplot as plt
import librosa
import numpy as np
import argparse


def plot_nearest_distance_matrices(
    left_results,
    right_results,
    left_name,
    right_name,
    show_plots,
    num_metrics=10,
    output_dir="testing_mmm_audio/validation/validation_results",
):
    left_slug = left_name.lower().replace(" ", "_")
    right_slug = right_name.lower().replace(" ", "_")
    metrics_to_plot = min(num_metrics, len(left_results), len(right_results))

    for i in range(metrics_to_plot):
        left_line = [float(onset) for onset in left_results[i]]
        right_line = [float(onset) for onset in right_results[i]]

        if len(left_line) == 0 or len(right_line) == 0:
            print(
                f"Skipping distance matrix for metric {i} ({left_name} vs {right_name}) due to empty onset list."
            )
            continue

        distance_matrix = np.full((len(left_line), len(right_line)), np.nan)
        right_arr = np.array(right_line)
        for row_idx, left_onset in enumerate(left_line):
            distances = np.abs(right_arr - left_onset)
            nearest_col_idx = int(np.argmin(distances))
            distance_matrix[row_idx, nearest_col_idx] = distances[nearest_col_idx]

        fig, ax = plt.subplots(figsize=(8, 6))
        cmap = plt.cm.viridis.copy()
        cmap.set_bad(color='white')
        im = ax.imshow(distance_matrix, cmap=cmap, aspect='auto')
        fig.colorbar(im, label='Nearest Distance (samples)')
        ax.set_title(f"Distance Matrix - Metric {i} ({left_name} vs {right_name})")
        ax.set_xlabel(right_name)
        ax.set_ylabel(left_name)
        fig.tight_layout()
        if show_plots:
            plt.show(block=True)
        fig.savefig(
            f"{output_dir}/onset_comparison_metric={i}_01_distance_matrix_{left_slug}_vs_{right_slug}.png"
        )
        plt.close(fig)


def main(args):
    if args.show_plots:
        # Force blocking behavior so plots appear one at a time.
        plt.ioff()
    
    # run mojo analyses
    os.system("mojo run -I . ./testing_mmm_audio/validation/OnsetSlice_Validation.mojo")
    
    with open("testing_mmm_audio/validation/mojo_results/mojo_buf_onset_slice_points.csv", "r") as mojo_buf_file:
        csv_reader = csv.reader(mojo_buf_file)
        mojo_buf_results = [line for line in csv_reader]
    
    with open("testing_mmm_audio/validation/mojo_results/mojo_rt_onset_slice_points.csv", "r") as mojo_rt_file:
        csv_reader = csv.reader(mojo_rt_file)
        mojo_rt_results = [line for line in csv_reader]
    
    with open("testing_mmm_audio/validation/flucoma_sc_results/onset_detection_flucoma_slice_points.csv", "r") as sc_file:
        csv_reader = csv.reader(sc_file)
        sc_results = [line for line in csv_reader]
        
    # compare results
    for i in range(10):
        mojo_buf_line = mojo_buf_results[i]
        sc_line = sc_results[i]
        mojo_rt_line = mojo_rt_results[i]
        print(f"metric: {i} | SC n: {len(sc_line)} | Mojo buf n: {len(mojo_buf_line)} | Mojo RT n: {len(mojo_rt_line)}")
        
    y, sr = librosa.load("/Users/ted/dev/flucoma-core/Resources/AudioFiles/Nicol-LoopE-M.wav", sr=None)
        
    # plot and save each comparison
    for i in range(10):
        mojo_buf_line = mojo_buf_results[i]
        sc_line = sc_results[i]
        mojo_rt_line = mojo_rt_results[i]
        
        
        fig, ax = plt.subplots(figsize=(12, 4))
        ax.plot(y)
        
        # plot mojo results
        for onset in mojo_buf_line:
            # onset_sample = int(float(onset) * len(y))
            ax.axvline(x=float(onset), color='r', linestyle='--', label='Mojo Buf Onset' if onset == mojo_buf_line[0] else "")
        
        # plot mojo rt results
        for onset in mojo_rt_line:
            # onset_sample = int(float(onset) * len(y))
            ax.axvline(x=float(onset), color='b', linestyle='-.', label='Mojo RT Onset' if onset == mojo_rt_line[0] else "")
        
        # plot flucoma-sc results
        for onset in sc_line:
            # onset_sample = int(float(onset) * len(y))
            ax.axvline(x=float(onset), color='g', linestyle=':', label='Flucoma-SC Onset' if onset == sc_line[0] else "")
        
        ax.set_title(f"Onset Detection Comparison - Metric {i}")
        ax.set_xlabel("Sample Index")
        ax.set_ylabel("Amplitude")
        ax.legend()
        fig.tight_layout()
        if args.show_plots:
            plt.show(block=True)
        fig.savefig(f"testing_mmm_audio/validation/validation_results/onset_comparison_metric={i}_00_waveform.png")
        plt.close(fig)
        
    # Plot nearest-only distance matrices for each metric across all requested pairings.
    plot_nearest_distance_matrices(
        mojo_buf_results,
        sc_results,
        "Mojo Buf Onsets",
        "Flucoma-SC Onsets",
        args.show_plots,
    )
    plot_nearest_distance_matrices(
        mojo_rt_results,
        sc_results,
        "Mojo RT Onsets",
        "Flucoma-SC Onsets",
        args.show_plots,
    )
    plot_nearest_distance_matrices(
        mojo_buf_results,
        mojo_rt_results,
        "Mojo Buf Onsets",
        "Mojo RT Onsets",
        args.show_plots,
    )

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Run onset detection validation and generate plots.")
    parser.add_argument("--show-plots", action="store_true", help="Show plots after generation.")
    args = parser.parse_args()
    raise SystemExit(main(args))