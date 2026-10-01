# Machine Learning for Earth System Modeling: the Anemoi framework

Open material of the hands-on course "[Machine Learning for Earth System Modeling: the Anemoi framework](https://bsc-aifactory.eu/training/machine-learning-for-earth-system-modeling-the-anemoi-framework/)", organised by the [BSC AI Factory](https://bsc-aifactory.eu/) at the Barcelona Supercomputing Center (BSC).

## About

The course introduces machine learning for Earth system modeling and takes participants from raw geospatial data all the way to a trained forecasting model, using ECMWF's [Anemoi](https://github.com/ecmwf/anemoi-core) framework. Over four days it covers:

- requesting and downloading data from the Copernicus Climate Data Store (CDS);
- Earth system data formats and the creation of AI-ready (ARCO Zarr) datasets;
- the architecture and end-to-end pipeline of Anemoi;
- building and scaling Anemoi datasets from meteorological data;
- configuring and launching training runs of graph neural network (GNN) models;
- running forecast rollouts from trained models, and a final hackathon applying the complete pipeline.

It is aimed at scientists with intermediate expertise: comfortable programming in Python and familiar with weather and climate concepts (numerical weather prediction, reanalysis, GRIB/NetCDF, ERA5). A CDS account is needed to run the data-download notebook. The course was given in Barcelona by Joan Vedrí, Pai Peng Wang and Filippo Dainelli (BSC).

## Curriculum

| Day | Module | Topic | Notebook |
|-----|--------|-------|----------|
| 1 | 0 | Earth science data: download, preprocessing and ML-readiness | `notebooks/Module_0/` |
| 2 | 1 | Anemoi framework: introduction and package architecture | `notebooks/module-01.ipynb` |
| 2 | 2 | anemoi-datasets: creating and working with training datasets | `notebooks/module-02.ipynb` |
| 3 | 3 | anemoi-core: graph construction, model architecture and training | `notebooks/module-03-04/` |
| 3 | 4 | anemoi-inference: running forecast rollouts and visualising output | `notebooks/module-03-04/` |
| 4 | – | Hackathon: the complete pipeline on a dataset built by the participants | see [Hackathon reference material](#hackathon-reference-material) |

## What is in this repository

The notebooks in this repository are the ones used during the course; the lecture slides are not included.

- **Modules 0, 1 and 2** can be replicated on a laptop. Download the demo data (see [Demo Data](#demo-data)) and save it in the `data/` folder in the root directory of the repository, then install the environment and run the notebooks.
- **Modules 3 and 4** (`notebooks/module-03-04/`) train a small Anemoi model and run inference, so you need a GPU (CUDA) to run notebooks 2 and 3.

### Hackathon reference material

The repository also contains examples of how the Anemoi pipeline was set up for the hackathon: dataset creation (`configs/hackathon/*.yaml`, `scripts/hackathon-dataset/`), graph construction, training (`configs/hackathon/`, `scripts/hackathon-training/`) and inference (`notebooks/hackathon_inference.ipynb`, `configs/hackathon/model-inference.yaml`). They are meant as a **reference** to learn from and adapt. They are **not** ready-to-run scripts or ready-to-use Anemoi configurations: they contain placeholder paths (`path/to/data/folder`, `path/to/output/folder`), the scheduler settings of the SLURM scripts are left as comments to fill in for your own cluster, and they were developed for the specific HPC environment of the course.

## Environment Setup

### Running locally

If you want to run these notebooks on your own machine, the environment is managed with [uv](https://docs.astral.sh/uv/) and requires Python 3.12.

**1. Install uv**

```bash
curl -LsSf https://astral.sh/uv/install.sh | sh
```

Or via pip:

```bash
pip install uv
```

**2. Clone the repository and install the module environment**

Each module has its own dependency group. Install only the one you need (a plain `uv sync` installs all of them):

```bash
# Module 0 — Earth science data download and preprocessing
uv sync --group module-00

# Module 1 — Anemoi framework intro (full package stack)
uv sync --group module-01

# Module 2 — anemoi-datasets deep dive
uv sync --group module-02

# Modules 3–4 — graph, training and inference (notebooks 2–3 need a CUDA GPU)
uv sync --group module-03-04
```

Core dependencies (JupyterLab, matplotlib, cartopy, numpy, xarray, zarr, dask) are installed automatically for all modules.

**3. Launch JupyterLab**

```bash
uv run jupyter lab
```

## Demo Data

The `data/` directory is not tracked in this repository. The data is published in two Zenodo records:

- **Course data** (Modules 0–4): **[Zenodo — LINK TBD]**
- **Hackathon data** (ERA5 NetCDF files, 2010–2015): **[Zenodo — LINK TBD]**. Only needed to follow the hackathon reference material.

Download and extract the archive into the project root so the `data/` directory sits alongside `notebooks/` and `configs/`. The notebooks read all inputs from there. Files the notebooks create (including the CDS downloads of Module 0, Notebook 1) are written to `data/derived/module-00/` and `data/derived/module-02/` (created automatically), so the downloaded inputs are never modified.

### Course data


| Dataset | Used in | Description |
|---|---|---|
| `module-03_04/era5-o48-2020-2021-6h-v0.zarr`, `module-03_04/grids/grid-o32.npz` | Modules 03–04 | ERA5 O48, 2020–2021, 6h prepared store and the O32 grid points for the hidden mesh |
| `module-00/{ERA5,CERRA,CMIP6}/` | Module 00 (Notebooks 2–3) | Sample ERA5 and CERRA GRIB files (`ERA5-AIFTraining-M0-*.grib`, `CERRA-AIFTraining-M0-*.grib`) and a CMIP6 NetCDF — produced by Notebook 1 via the CDS API |
| `demo-ea-an-oper-0001-mars-o48-202001-202006-6h-v1.zarr` | Modules 01, 02 | ERA5 O48, Jan–Jun 2020, 6h, 43 variables — pre-built zarr |
| `demo-ea-an-oper-0001-mars-o96-202001-202001-6h-v1/` | Module 02 | ERA5 O96, Jan 2020, 6h — source GRIBs (sfc, pl, acc) + pre-built zarr |
| `demo-ea-an-oper-0001-cdsapi-ll1x1-202001-202001-6h-v1/` | Module 02 | ERA5 1x1 regular lat/lon, Jan 2020 — source NetCDFs (`_sfc.nc`, `_pl.nc`, `_acc.nc`, hourly precipitation), no index needed |
| `demo-cerra-rr-an-oper-0001-cdsapi-5p5km-20200101-20200115-6h-v1/` | Module 02 | CERRA 5.5 km, Jan 1–15 2020, 6h — source GRIBs + pre-built zarr |
| `demo-cerra-rr-an-oper-0001-cdsapi-5p5km-20200101-20200107-3h-v1/` | Module 02 | CERRA 5.5 km, Jan 1–7 2020, 3h — source GRIBs + pre-built zarr |

Each directory containing source GRIBs (the NetCDF directory holds the same three groups as `.nc` files) includes three files (`_sfc.grib`, `_pl.grib`, `_acc.grib`) and the corresponding SQLite grib-index (`_acc_index.sqlite`). The Module 02 notebook rebuilds these indexes from scratch as part of the demo.

### Hackathon data

Extract the hackathon record into `data/hackathon/`, keeping its `pl/` and `sl/` subfolders. These are the yearly ERA5 files (regular 1° lat-lon, 6-hourly) that the hackathon dataset recipes in `configs/hackathon/` read; point the `path/to/data/folder` placeholders there to this folder.

| Files | Description |
|---|---|
| `hackathon/pl/hackathon-ea-an-oper-0001-mars-ll1x1-<year>01-<year>12-6h_pl.nc` | Pressure-level variables (q, t, u, v, z), one file per year |
| `hackathon/sl/hackathon-ea-an-oper-0001-mars-ll1x1-<year>01-<year>12-6h_sfc.nc` | Surface variables, one file per year |
| `hackathon/sl/hackathon-ea-an-oper-0001-mars-ll1x1-<year>01-<year>12-6h_acc.nc` | Total precipitation accumulated over 6 h, one file per year |

## Modules 3–4

Modules 3–4 (`notebooks/module-03-04/`) train a small Anemoi model and run inference, so notebooks 2 and 3 need a CUDA GPU. Run the notebooks in order, 0 to 3; `extra/` holds optional background notebooks. Inputs are read from `data/module-03_04/` (it must contain `era5-o48-2020-2021-6h-v0.zarr` and `grids/grid-o32.npz`) and outputs are written to `output/module-03_04/`. To use other locations, set `ANEMOI_COURSE_DATA` and `ANEMOI_COURSE_OUTPUT` before launching JupyterLab.
