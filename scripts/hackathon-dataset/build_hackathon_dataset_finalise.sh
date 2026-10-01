#!/bin/bash
#SBATCH --job-name=hackathon-dataset-finalise
#SBATCH --time=01:00:00
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
# Add the settings your cluster needs, for example:
##SBATCH --account=<your-project-account>
##SBATCH --qos=<queue-for-cpu-jobs>
##SBATCH --output=<log-dir>/%x-%j.out
##SBATCH --error=<log-dir>/%x-%j.err

# Stage 3/3 of the parallel hackathon dataset build: consolidate metadata/statistics and validate.
# Launched by build_hackathon_dataset_parallel.sh

set -euo pipefail

OUTPUT=$1

echo "Job started: $(date)"
echo "Output:      ${OUTPUT}"

# Activate the Python environment with the anemoi packages
# source path/to/.venv/bin/activate

# Optional: the regrid filter looks up named grids (O96, ...) online. Without internet access on the compute
# nodes, pre-fetch them from a node that has it and point anemoi to that folder:
# export ANEMOI_CONFIG_UTILS_GRIDS_PATH=/path/to/anemoi-grids

anemoi-datasets finalise "${OUTPUT}"
anemoi-datasets cleanup "${OUTPUT}"
anemoi-datasets patch "${OUTPUT}"

# Patching the resolution value in the metadata if you regrid to 096 otherwise comment or change
RESOLUTION=O96
python -c "
from anemoi.datasets.create.dataset import Dataset
Dataset('${OUTPUT}', update=True).update_metadata(resolution='${RESOLUTION}')
"

anemoi-datasets inspect "${OUTPUT}"

echo "Job finished: $(date)"
