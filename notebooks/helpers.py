from __future__ import annotations

from collections.abc import Sequence
from pathlib import Path

import cartopy.crs as ccrs
import matplotlib.pyplot as plt
import matplotlib.tri as mtri
import numpy as np
from anemoi.datasets import open_dataset
from matplotlib.figure import Figure

_UNIT_CONVERSIONS: dict[str, tuple[float, float, str]] = {
    "2t": (273.15, 1.0, "°C"),
    "2d": (273.15, 1.0, "°C"),
    "skt": (273.15, 1.0, "°C"),
    "t": (273.15, 1.0, "°C"),
    "msl": (0.0, 100.0, "hPa"),
    "sp": (0.0, 100.0, "hPa"),
    "z": (0.0, 9.80665, "gpm"),
    "tp": (0.0, 0.001, "mm"),
    "10u": (0.0, 1.0, "m/s"),
    "10v": (0.0, 1.0, "m/s"),
    "u": (0.0, 1.0, "m/s"),
    "v": (0.0, 1.0, "m/s"),
    "q": (0.0, 1.0e-3, "g/kg"),
    "tcw": (0.0, 1.0, "kg/m²"),
}


def to_plot_units(variable: str, values: np.ndarray) -> tuple[np.ndarray, str]:
    """Convert values from the units stored in the dataset to plotting units."""
    key = variable.split("_")[0]
    offset, divisor, unit = _UNIT_CONVERSIONS.get(key, (0.0, 1.0, ""))
    return (values - offset) / divisor, unit


def wrap_longitudes(longitudes: np.ndarray) -> np.ndarray:
    """Return longitudes in [-180, 180) from longitudes in [0, 360)."""
    return ((longitudes + 180.0) % 360.0) - 180.0


def build_triangulation(longitudes: np.ndarray, latitudes: np.ndarray):
    """Build a Delaunay triangulation of an unstructured grid, for map plots."""
    wrapped = wrap_longitudes(longitudes)
    triangulation = mtri.Triangulation(wrapped, latitudes)
    longitude_spans = np.ptp(wrapped[triangulation.triangles], axis=1)
    triangulation.set_mask(longitude_spans > 180.0)
    return triangulation


def build_projected_triangulation(
    longitudes: np.ndarray, latitudes: np.ndarray, projection: ccrs.Projection
):
    """Build the triangulation with its nodes in the coordinates of a map projection.

    Same triangles as ``build_triangulation`` (antimeridian masked), with the nodes
    moved to the projection: needed to draw with ``tripcolor`` on any projection
    other than PlateCarree. Triangles with a non-finite corner are also masked.
    """
    triangulation = build_triangulation(longitudes, latitudes)
    xy = projection.transform_points(
        ccrs.PlateCarree(), triangulation.x, triangulation.y
    )
    x_proj, y_proj = xy[:, 0], xy[:, 1]
    not_finite = ~np.all(np.isfinite(x_proj[triangulation.triangles]), axis=1) | ~(
        np.all(np.isfinite(y_proj[triangulation.triangles]), axis=1)
    )
    projected = mtri.Triangulation(x_proj, y_proj, triangles=triangulation.triangles)
    projected.set_mask(triangulation.mask | not_finite)
    return projected


def load_truth(
    dataset_path: str | Path,
    variables: Sequence[str],
    dates: Sequence[np.datetime64],
) -> dict[str, np.ndarray]:
    """Read the verifying fields of an anemoi dataset at the given valid times."""
    dataset = open_dataset(str(dataset_path), select=list(variables))
    index_of_date = {np.datetime64(d, "s"): i for i, d in enumerate(dataset.dates)}
    missing = [d for d in dates if np.datetime64(d, "s") not in index_of_date]
    if missing:
        raise ValueError(f"Dates not in the dataset: {missing[:3]} ...")
    indices = [index_of_date[np.datetime64(d, "s")] for d in dates]
    # one date at a time: indexing a selected dataset with a list of dates is not
    # reliable. Each date has the layout (variables, ensemble members, grid points)
    fields = np.stack([np.asarray(dataset[i])[:, 0, :] for i in indices])
    return {name: fields[:, i, :] for i, name in enumerate(dataset.variables)}


def plot_map_panels(
    truth: np.ndarray,
    forecast: np.ndarray,
    longitudes: np.ndarray,
    latitudes: np.ndarray,
    variable: str,
    title: str,
    projection: ccrs.Projection | None = None,
) -> Figure:
    """Plot truth, forecast and forecast error side by side on a world map.

    Same map style as the Module 2 notebook: Robinson projection by default, a
    triangulation built in projection coordinates, light dashed gridlines.
    """
    projection = projection if projection is not None else ccrs.Robinson()
    truth, unit = to_plot_units(variable, truth)
    forecast, _ = to_plot_units(variable, forecast)
    error = forecast - truth

    # built once: the same grid for the three panels
    triangulation = build_projected_triangulation(longitudes, latitudes, projection)
    vmin = min(truth.min(), forecast.min())
    vmax = max(truth.max(), forecast.max())
    error_limit = float(np.abs(error).max())

    panels = [
        ("Truth", truth, "coolwarm", vmin, vmax),
        ("Forecast", forecast, "coolwarm", vmin, vmax),
        ("Error (forecast - truth)", error, "RdBu_r", -error_limit, error_limit),
    ]
    fig, axes = plt.subplots(
        1,
        3,
        figsize=(18, 4.5),
        subplot_kw={"projection": projection},
        constrained_layout=True,
    )
    for ax, (name, values, cmap, low, high) in zip(axes, panels):
        # no transform=: the triangulation nodes are already in projection coordinates
        image = ax.tripcolor(
            triangulation, values, shading="gouraud", cmap=cmap, vmin=low, vmax=high
        )
        ax.coastlines(resolution="110m", linewidth=0.6)
        ax.gridlines(draw_labels=False, linewidth=0.3, alpha=0.5, linestyle="--")
        ax.set_global()
        ax.set_title(name)
        fig.colorbar(
            image, ax=ax, orientation="horizontal", pad=0.05, shrink=0.6, label=unit
        )
    fig.suptitle(title)
    return fig
