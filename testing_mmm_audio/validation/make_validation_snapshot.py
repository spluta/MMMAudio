import argparse
import datetime as dt
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
    return os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))


def testing_dir() -> str:
    return os.path.join(repo_root(), "testing")


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


def build_snapshot(show_plots: bool) -> dict[str, Any]:
    results: dict[str, Any] = {
        "created_at": dt.datetime.now(dt.timezone.utc).isoformat(),
        "scripts": {},
    }

    scripts = validation_scripts()
    if not scripts:
        raise RuntimeError("No *_Validation.py scripts found under testing/.")

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

        results["scripts"][name] = {
            "stats": stats,
        }

    return results


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Run validation scripts and create/update testing/validation_snapshot.json"
    )
    parser.add_argument(
        "--show-plots",
        action="store_true",
        help="Pass --show-plots to each validation script",
    )
    args = parser.parse_args()

    os.makedirs(testing_dir(), exist_ok=True)

    try:
        snapshot = build_snapshot(show_plots=args.show_plots)
    except Exception as exc:
        print(f"Error: {exc}", file=sys.stderr)
        return 1

    out_path = snapshot_path()
    with open(out_path, "w", encoding="utf-8") as f:
        json.dump(snapshot, f, indent=2)
        f.write("\n")

    print(f"Wrote snapshot to {out_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
