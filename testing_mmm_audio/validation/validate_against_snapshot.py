import argparse
import glob
import json
import os
import re
import subprocess
import sys
from typing import Any

STAT_PREFIXES = ("MMMAudio vs Librosa", "MMMAudio vs FluCoMa")
FLOAT_RE = re.compile(r"[-+]?\d*\.?\d+(?:[eE][-+]?\d+)?")


def repo_root() -> str:
    return os.path.abspath(os.path.join(os.path.dirname(__file__), "../.."))


def testing_dir() -> str:
    return os.path.join(repo_root(), "testing_mmm_audio/validation")


def snapshot_path() -> str:
    return os.path.join(testing_dir(), "validation_snapshot.json")


def validation_scripts() -> list[str]:
    scripts = sorted(glob.glob(os.path.join(testing_dir(), "*_Validation.py")))
    return [s for s in scripts if os.path.basename(s) not in {"run_all_validations.py"}]


def extract_stats(stdout: str) -> list[dict[str, Any]]:
    stats: list[dict[str, Any]] = []
    for raw_line in stdout.splitlines():
        line = raw_line.strip()
        if not line:
            continue
        if not line.startswith(STAT_PREFIXES):
            continue

        label = line.split(":", 1)[0].strip()
        values = [float(v) for v in FLOAT_RE.findall(line)]
        stats.append({
            "label": label,
            "line": line,
            "values": values,
        })
    return stats


def run_validation(script_path: str, show_plots: bool) -> tuple[int, str, str]:
    cmd = [sys.executable, script_path]
    if show_plots:
        cmd.append("--show-plots")

    proc = subprocess.run(
        cmd,
        cwd=repo_root(),
        capture_output=True,
        text=True,
    )
    return proc.returncode, proc.stdout, proc.stderr


def compare_values(expected: list[float], actual: list[float], atol: float, rtol: float) -> bool:
    if len(expected) != len(actual):
        return False

    for exp, act in zip(expected, actual):
        tolerance = atol + rtol * abs(exp)
        if abs(exp - act) > tolerance:
            return False
    return True


def current_results(show_plots: bool) -> dict[str, Any]:
    out: dict[str, Any] = {"scripts": {}}
    scripts = validation_scripts()
    if not scripts:
        raise RuntimeError("No *_Validation.py scripts found under testing_mmm_audio/.")

    for script in scripts:
        name = os.path.basename(script)
        print(f"Running {name}...")
        returncode, stdout, stderr = run_validation(script, show_plots)
        if returncode != 0:
            print(stdout)
            print(stderr, file=sys.stderr)
            raise RuntimeError(f"Validation script failed: {name}")

        stats = extract_stats(stdout)
        if not stats:
            raise RuntimeError(
                f"No MMMAudio vs Librosa/FluCoMa stats found in output for {name}."
            )

        out["scripts"][name] = {"stats": stats}

    return out


def load_snapshot() -> dict[str, Any]:
    pth = snapshot_path()
    if not os.path.exists(pth):
        raise FileNotFoundError(
            f"Snapshot file not found at {pth}. Run make_validation_snapshot.py first."
        )

    with open(pth, "r", encoding="utf-8") as f:
        data = json.load(f)

    if "scripts" not in data or not isinstance(data["scripts"], dict):
        raise RuntimeError("Snapshot format invalid: missing 'scripts' object.")

    return data


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Run validation scripts and compare against testing_mmm_audio/validation_snapshot.json"
    )
    parser.add_argument(
        "--show-plots",
        action="store_true",
        help="Pass --show-plots to each validation script",
    )
    parser.add_argument(
        "--atol",
        type=float,
        default=1e-6,
        help="Absolute tolerance for numeric stat comparison",
    )
    parser.add_argument(
        "--rtol",
        type=float,
        default=0.0,
        help="Relative tolerance for numeric stat comparison",
    )
    args = parser.parse_args()

    try:
        expected = load_snapshot()
        actual = current_results(show_plots=args.show_plots)
    except Exception as exc:
        print(f"Error: {exc}", file=sys.stderr)
        return 1

    failures: list[str] = []

    expected_scripts = expected["scripts"]
    actual_scripts = actual["scripts"]

    missing_scripts = sorted(set(expected_scripts.keys()) - set(actual_scripts.keys()))
    extra_scripts = sorted(set(actual_scripts.keys()) - set(expected_scripts.keys()))

    for script_name in missing_scripts:
        failures.append(f"Missing script in current run: {script_name}")
    for script_name in extra_scripts:
        failures.append(f"Script not present in snapshot: {script_name}")

    shared_scripts = sorted(set(expected_scripts.keys()) & set(actual_scripts.keys()))
    for script_name in shared_scripts:
        expected_stats = expected_scripts[script_name].get("stats", [])
        actual_stats = actual_scripts[script_name].get("stats", [])

        expected_by_label = {item["label"]: item for item in expected_stats}
        actual_by_label = {item["label"]: item for item in actual_stats}

        missing_labels = sorted(set(expected_by_label.keys()) - set(actual_by_label.keys()))
        extra_labels = sorted(set(actual_by_label.keys()) - set(expected_by_label.keys()))

        for label in missing_labels:
            failures.append(f"{script_name}: Missing stat line '{label}'")
        for label in extra_labels:
            failures.append(f"{script_name}: Extra stat line '{label}'")

        for label in sorted(set(expected_by_label.keys()) & set(actual_by_label.keys())):
            exp_values = expected_by_label[label].get("values", [])
            act_values = actual_by_label[label].get("values", [])
            if not compare_values(exp_values, act_values, args.atol, args.rtol):
                failures.append(
                    f"{script_name}: Stat mismatch for '{label}'. "
                    f"expected={exp_values} actual={act_values}"
                )

    if failures:
        print("Snapshot validation FAILED:")
        for failure in failures:
            print(f"- {failure}")
        return 1

    print("Snapshot validation PASSED: current validation stats match snapshot.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
