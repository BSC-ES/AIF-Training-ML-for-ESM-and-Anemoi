"""Environment checks and helpers for the Modules 3–4 notebooks.

The setup cell of each notebook defines the paths; this module only checks that the pinned packages
(from pyproject.toml), the course inputs, the output directory and (optionally) the GPU are in place.
No package installation or download happens here.
"""
from __future__ import annotations

import importlib.metadata
import json
import tomllib
import uuid
from pathlib import Path

import numpy as np

REPO = Path(__file__).resolve().parents[2]
MODULE_GROUP = "module-03-04"


def check_pinned_versions():
    """Compare the installed packages with the `==` pins of the module group in pyproject.toml."""
    pyproject = tomllib.loads((REPO / "pyproject.toml").read_text())
    mismatches = []
    for requirement in pyproject["dependency-groups"][MODULE_GROUP]:
        name, _, expected = requirement.partition("==")
        if not expected:
            continue
        try:
            actual = importlib.metadata.version(name)
        except importlib.metadata.PackageNotFoundError:
            actual = "missing"
        if actual != expected:
            mismatches.append(f"{name}: expected {expected}, found {actual}")
    if mismatches:
        raise RuntimeError(
            f"This kernel does not have the pinned {MODULE_GROUP} environment. From the repository root run "
            f"`uv sync --group {MODULE_GROUP}`, start JupyterLab with `uv run jupyter lab`, and select the "
            "`python3` kernel.\n" + "\n".join(mismatches)
        )


def require_gpu():
    import socket
    import torch
    if not torch.cuda.is_available():
        raise RuntimeError(
            "No CUDA GPU visible: Notebooks 2 and 3 need one (a driver supporting CUDA 12.8 or newer). "
            "Notebooks 0 and 1 run without a GPU."
        )
    return {"host": socket.gethostname(),
            "gpu": torch.cuda.get_device_name(0),
            "capacity_gib": round(torch.cuda.get_device_properties(0).total_memory / 2**30, 2)}


def check_environment(dataset: Path, grid: Path, output: Path, *, gpu: bool):
    """Check the pinned packages, the course inputs, the output directory and (optionally) the GPU."""
    check_pinned_versions()
    if "artifacts" in output.parts:
        raise ValueError("This MLflow version rejects stores beneath an artifacts directory; choose another directory for ANEMOI_COURSE_OUTPUT.")
    for path in (dataset / "data/.zarray", grid):
        try:
            with path.open("rb"):
                pass
        except OSError as exc:
            raise RuntimeError(
                f"Cannot read course asset: {path}\n{exc}\n"
                "Download the course data (https://doi.org/10.5281/zenodo.23099483) and run "
                "`unzip course-module-03_04.zip` from the repository root so that "
                "data/module-03_04/ holds the dataset and grids/. Otherwise set "
                "ANEMOI_COURSE_DATA to a readable prepared input directory. "
                "Restart the kernel and rerun the setup cell."
            ) from exc
    try:
        output.mkdir(parents=True, exist_ok=True)
        probe = output / f".write-check-{uuid.uuid4().hex}"
        probe.write_text("ok")
        probe.unlink()
    except OSError as exc:
        raise RuntimeError(
            f"Cannot write course outputs: {output}\n{exc}\n"
            "Set ANEMOI_COURSE_OUTPUT to a writable directory. "
            "Restart the kernel and rerun the setup cell."
        ) from exc
    info = {"dataset": str(dataset), "output": str(output)}
    if gpu:
        info.update(require_gpu())
    print(json.dumps(info, indent=2))
    return info


def metric_history(result):
    import mlflow
    import pandas as pd
    client = mlflow.tracking.MlflowClient(tracking_uri=result["tracking_uri"])
    run = client.get_run(result["run_id"])
    rows = []
    for name in run.data.metrics:
        if "mse" in name.lower() or "loss" in name.lower():
            for point in client.get_metric_history(run.info.run_id, name):
                rows.append({"metric": name, "step": point.step, "value": point.value})
    if not rows or not all(np.isfinite(row["value"]) for row in rows):
        raise RuntimeError("This run has missing or non-finite loss metrics; inspect its training log.")
    return pd.DataFrame(rows)
