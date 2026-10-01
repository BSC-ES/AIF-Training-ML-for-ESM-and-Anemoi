#!/bin/bash
#SBATCH --job-name=hackathon-dataset-load
#SBATCH --time=00:30:00
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
# Add the settings your cluster needs, for example:
##SBATCH --account=<your-project-account>
##SBATCH --qos=<queue-for-cpu-jobs>
##SBATCH --output=<log-dir>/%x-%j.out
##SBATCH --error=<log-dir>/%x-%j.err

# Stage 2/3 of the parallel hackathon dataset build: load one part of the store's date groups.
# Launched by build_hackathon_dataset_parallel.sh.

set -euo pipefail

OUTPUT=$1
N=$2

# Guard against running this script directly, rather than via sbatch --array=1-N%C, which sets SLURM_ARRAY_TASK_ID.
if [ -z "${SLURM_ARRAY_TASK_ID:-}" ]; then
  echo "SLURM_ARRAY_TASK_ID is unset -- this script must be submitted with --array=1-N%C, not run directly." >&2
  exit 1
fi

echo "Job started: $(date)"
echo "Output:      ${OUTPUT}"
echo "Part:        ${SLURM_ARRAY_TASK_ID}/${N}"

# Activate the Python environment with the anemoi packages
# source path/to/.venv/bin/activate

# Optional: the regrid filter looks up named grids (O96, ...) online. Without internet access on the compute
# nodes, pre-fetch them from a node that has it and point anemoi to that folder:
# export ANEMOI_CONFIG_UTILS_GRIDS_PATH=/path/to/anemoi-grids

anemoi-datasets load "${OUTPUT}" --parts "${SLURM_ARRAY_TASK_ID}/${N}"

echo "Job finished: $(date)"
