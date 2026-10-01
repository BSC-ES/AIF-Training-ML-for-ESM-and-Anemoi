#!/bin/bash
#SBATCH --job-name=hackathon-dataset-init
#SBATCH --time=00:15:00
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=2
# Add the settings your cluster needs, for example:
##SBATCH --account=<your-project-account>
##SBATCH --qos=<queue-for-cpu-jobs>
##SBATCH --output=<log-dir>/%x-%j.out
##SBATCH --error=<log-dir>/%x-%j.err

# Stage 1/3 of the parallel build: allocate the zarr store. 
# Launched by build_hackathon_dataset_parallel.sh

set -euo pipefail

CONFIG=$1
OUTPUT=$2

echo "Job started: $(date)"
echo "Config:      ${CONFIG}"
echo "Output:      ${OUTPUT}"

# Activate the Python environment with the anemoi packages
# source path/to/.venv/bin/activate

# Optional: the regrid filter looks up named grids (O96, ...) online. Without internet access on the compute
# nodes, pre-fetch them from a node that has it and point anemoi to that folder:
# export ANEMOI_CONFIG_UTILS_GRIDS_PATH=/path/to/anemoi-grids

mkdir -p "$(dirname "$OUTPUT")"

anemoi-datasets init "${CONFIG}" "${OUTPUT}" --overwrite

echo "Job finished: $(date)"
