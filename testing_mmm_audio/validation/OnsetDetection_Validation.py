import os
import csv
import matplotlib.pyplot as plt
import librosa
import numpy as np
import subprocess


WAVEFORM_FIGSIZE = (16, 6)
ODF_FIGSIZE = (16, 6)
DISTANCE_MATRIX_FIGSIZE = (12, 9)
PLOT_DPI = 200
DEFAULT_AUDIO_PATH = "/Users/ted/dev/flucoma-core/Resources/AudioFiles/Nicol-LoopE-M.wav"

def plot_nearest_distance_matrices(
    left_results,
    right_results,
    left_name,
    right_name,
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

        fig, ax = plt.subplots(figsize=DISTANCE_MATRIX_FIGSIZE, dpi=PLOT_DPI)
        cmap = plt.cm.viridis.copy()
        cmap.set_bad(color='white')
        vmax = max(1024.0, float(np.nanmax(distance_matrix)))
        im = ax.imshow(distance_matrix, cmap=cmap, aspect='auto', vmin=0.0, vmax=vmax)
        fig.colorbar(im, label='Nearest Distance (samples)')
        ax.set_title(f"Distance Matrix - Metric {i} ({left_name} vs {right_name})")
        ax.set_xlabel(right_name)
        ax.set_ylabel(left_name)
        fig.tight_layout()
        fig.savefig(
            f"{output_dir}/onset_comparison_metric={i}_02_distance_matrix_{left_slug}_vs_{right_slug}.png",
            dpi=PLOT_DPI,
        )
        plt.close(fig)


def compare_nearest_distances(left_results, right_results):
    nearest_distances = []

    for left_line, right_line in zip(left_results, right_results):
        left_values = [float(value) for value in left_line]
        right_values = [float(value) for value in right_line]

        if len(left_values) == 0 or len(right_values) == 0:
            continue

        right_arr = np.array(right_values)
        for left_value in left_values:
            distances = np.abs(right_arr - left_value)
            nearest_distances.append(float(np.min(distances)))

    if not nearest_distances:
        return 0.0, 0.0

    distance_arr = np.array(nearest_distances)
    return float(np.mean(distance_arr)), float(np.std(distance_arr))


def read_onset_rows(file_path, expected_metrics=10):
    with open(file_path, "r", encoding="utf-8") as csv_file:
        csv_reader = csv.reader(csv_file)
        rows = [line for line in csv_reader]

    while len(rows) < expected_metrics:
        rows.append([])

    return rows[:expected_metrics]


def plot_onset_markers(ax, onset_values, color, linestyle, label):
    if not onset_values:
        return

    for onset_index, onset in enumerate(onset_values):
        ax.axvline(
            x=float(onset),
            color=color,
            linestyle=linestyle,
            label=label if onset_index == 0 else "",
        )


def resolve_audio_path():
    env_audio_path = os.environ.get("ONSET_DETECTION_AUDIO_PATH")
    if env_audio_path and os.path.exists(env_audio_path):
        return env_audio_path

    return DEFAULT_AUDIO_PATH


def main():
    audio_path = resolve_audio_path()

    if not os.path.exists(audio_path):
        raise FileNotFoundError(f"Audio file not found: {audio_path}")

    # run mojo analyses
    subprocess.run(
        [
            "mojo",
            "run",
            "-I",
            ".",
            "./testing_mmm_audio/validation/OnsetDetection_Validation.mojo",
            "--audio-path",
            audio_path,
        ],
        check=True,
    )
    
    mojo_buf_results = read_onset_rows(
        "testing_mmm_audio/validation/mojo_results/mojo_buf_onset_detection_points.csv"
    )

    mojo_rt_results = read_onset_rows(
        "testing_mmm_audio/validation/mojo_results/mojo_rt_onset_detection_points.csv"
    )

    sc_results = read_onset_rows(
        "testing_mmm_audio/validation/flucoma_sc_results/onset_detection_flucoma_slice_points.csv"
    )
        
    # compare results
    for i in range(10):
        mojo_buf_line = mojo_buf_results[i]
        sc_line = sc_results[i]
        mojo_rt_line = mojo_rt_results[i]
        print(f"metric: {i} | SC n: {len(sc_line)} | Mojo buf n: {len(mojo_buf_line)} | Mojo RT n: {len(mojo_rt_line)}")

    mojo_buf_vs_flucoma_mean, mojo_buf_vs_flucoma_std = compare_nearest_distances(mojo_buf_results, sc_results)
    print(
        f"MMMAudio vs FluCoMa Onset Detection Buffered: Mean Dev = {mojo_buf_vs_flucoma_mean:.2f} samples, Std Dev = {mojo_buf_vs_flucoma_std:.2f} samples"
    )

    mojo_rt_vs_flucoma_mean, mojo_rt_vs_flucoma_std = compare_nearest_distances(mojo_rt_results, sc_results)
    print(
        f"MMMAudio vs FluCoMa Onset Detection Real-Time: Mean Dev = {mojo_rt_vs_flucoma_mean:.2f} samples, Std Dev = {mojo_rt_vs_flucoma_std:.2f} samples"
    )
        
    y, sr = librosa.load(audio_path, sr=None)
        
    # plot and save each comparison
    for i in range(10):
        mojo_buf_line = mojo_buf_results[i]
        sc_line = sc_results[i]
        mojo_rt_line = mojo_rt_results[i]
        
        
        fig, ax = plt.subplots(figsize=WAVEFORM_FIGSIZE, dpi=PLOT_DPI)
        ax.plot(y)
        
        # plot mojo results
        plot_onset_markers(ax, mojo_buf_line, 'r', '--', 'Mojo Buf Onset')
        
        # plot mojo rt results
        plot_onset_markers(ax, mojo_rt_line, 'b', '-.', 'Mojo RT Onset')
        
        # plot flucoma-sc results
        plot_onset_markers(ax, sc_line, 'g', ':', 'Flucoma-SC Onset')
        
        ax.set_title(f"Onset Detection Comparison - Metric {i}")
            
        ax.set_xlabel("Sample Index")
        ax.set_ylabel("Amplitude")
        ax.legend()
        fig.tight_layout()
        fig.savefig(
            f"testing_mmm_audio/validation/validation_results/onset_comparison_metric={i}_01_waveform.png",
            dpi=PLOT_DPI,
        )
        plt.close(fig)
        
    # Plot nearest-only distance matrices for each metric across all requested pairings.
    plot_nearest_distance_matrices(
        mojo_buf_results,
        sc_results,
        "Mojo Buf Onsets",
        "Flucoma-SC Onsets"
    )
    plot_nearest_distance_matrices(
        mojo_rt_results,
        sc_results,
        "Mojo RT Onsets",
        "Flucoma-SC Onsets"
    )
    plot_nearest_distance_matrices(
        mojo_buf_results,
        mojo_rt_results,
        "Mojo Buf Onsets",
        "Mojo RT Onsets"
    )
    
    # features time series
    
    with open("testing_mmm_audio/validation/mojo_results/mojo_buf_odf_time_series.csv", "r") as f:
        csv_reader = csv.reader(f)
        mojo_buf_odf_time_series = [line for line in csv_reader]
        
    with open("testing_mmm_audio/validation/flucoma_sc_results/onset_detection_features_flucoma.csv", "r") as f:
        csv_reader = csv.reader(f)
        flucoma_buf_odf_time_series = [line for line in csv_reader]
        
    # plot to compare all 10
    for i in range(10):
        mojo_buf_line = [float(x) for x in mojo_buf_odf_time_series[i]]
        flucoma_buf_line = [float(x) for x in flucoma_buf_odf_time_series[i]]
        
        fig, ax = plt.subplots(figsize=ODF_FIGSIZE, dpi=PLOT_DPI)
        ax.plot(mojo_buf_line, color='r', label='Mojo Buf ODF')
        ax.plot(flucoma_buf_line, color='g', label='Flucoma-SC ODF')
        
        ax.set_title(f"Onset Detection Feature Comparison - Metric {i}")
        ax.set_xlabel("Frame Index")
        ax.set_ylabel("ODF Value")
        if i == 4:
            ax.set_ylim(-100, 3000)  # Zoom in for metric 4
        ax.legend()
        fig.tight_layout()
        fig.savefig(
            f"testing_mmm_audio/validation/validation_results/onset_comparison_metric={i}_00_odf_time_series.png",
            dpi=PLOT_DPI,
        )
        plt.close(fig)

if __name__ == "__main__":
    raise SystemExit(main())