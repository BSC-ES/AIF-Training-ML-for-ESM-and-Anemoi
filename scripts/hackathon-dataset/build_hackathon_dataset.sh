#!/bin/bash
#SBATCH --job-name=hackathon-dataset
#SBATCH --time=00:30:00
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
# Add the settings your cluster needs, for example:
##SBATCH --account=<your-project-account>
##SBATCH --qos=<queue-for-cpu-jobs>
##SBATCH --output=<log-dir>/%x-%j.out
##SBATCH --error=<log-dir>/%x-%j.err

# Build a hackathon ERA5 anemoi-dataset with a serial anemoi-dataset create command.
# Usage:
# 
#   sbatch scripts/hackathon-dataset/build_hackathon_dataset.sh path/to/recipe.yaml
#   (or, without a scheduler: bash scripts/hackathon-dataset/build_hackathon_dataset.sh path/to/recipe.yaml)

set -euo pipefail

CONFIG=$(realpath "${1:?usage: build_hackathon_dataset.sh <recipe.yaml>}")
# Same placeholder root as in configs/hackathon/*.yaml: edit it here (or export OUTPUT_ROOT) to your own output folder.
OUTPUT_ROOT=${OUTPUT_ROOT:-path/to/output/folder}
DATA_DIR=$OUTPUT_ROOT/data   # where the built zarr is written
OUTPUT=$DATA_DIR/$(basename "${CONFIG%.*}").zarr

echo "Job started: $(date)"
echo "Config:      ${CONFIG}"
echo "Output:      ${OUTPUT}"

# Activate the Python environment with the anemoi packages
# source path/to/.venv/bin/activate

# Optional: the regrid filter looks up named grids (O96, ...) online. Without internet access on the compute
# nodes, pre-fetch them from a node that has it and point anemoi to that folder:
# export ANEMOI_CONFIG_UTILS_GRIDS_PATH=/path/to/anemoi-grids

# Ensuring the data directory exists before submitting jobs
mkdir -p "$DATA_DIR"

anemoi-datasets create "${CONFIG}" "${OUTPUT}" --overwrite

# Patching the resolution value in the metadata if you regrid to 096 otherwise comment or change
RESOLUTION=O96
python -c "
from anemoi.datasets.create.dataset import Dataset
Dataset('${OUTPUT}', update=True).update_metadata(resolution='${RESOLUTION}')
"

anemoi-datasets inspect "${OUTPUT}"

echo "Job finished: $(date)"
