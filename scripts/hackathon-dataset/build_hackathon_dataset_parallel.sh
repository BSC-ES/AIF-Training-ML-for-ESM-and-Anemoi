#!/bin/bash

# Parallel build of a hackathon ERA5 anemoi-dataset on a SLURM cluster (init -> load array -> finalise). The output zarr's name defaults to the
# recipe's own filename (e.g. recipe.yaml -> recipe.zarr) but can be overridden, and so can N (the
# number of parallel parts).
# To launch the parallel build, run one of the following commands from the main directory:
#
#   bash scripts/build_hackathon_dataset_parallel.sh path/to/recipe.yaml
#   bash scripts/build_hackathon_dataset_parallel.sh path/to/recipe.yaml [output_name]
#   bash scripts/build_hackathon_dataset_parallel.sh path/to/recipe.yaml [output_name] [N]

set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

CONFIG=$(realpath "${1:?usage: build_hackathon_dataset_parallel.sh <recipe.yaml> [output_name] [N]}")
# Same placeholder root as in configs/hackathon/*.yaml: edit it here (or export OUTPUT_ROOT) to your own output folder.
OUTPUT_ROOT=${OUTPUT_ROOT:-path/to/output/folder}
DATA_DIR=$OUTPUT_ROOT/data   # where the built zarr is written

# Output name: use the 2nd argument if given, otherwise fall back to the recipe's own filename.
OUTPUT_NAME=${2:-$(basename "${CONFIG%.*}")}
OUTPUT_NAME=${OUTPUT_NAME%.zarr}
OUTPUT=$DATA_DIR/${OUTPUT_NAME}.zarr

# Default N: count calendar months spanned by dates.start/dates.end.
default_n() {
  local start_ym end_ym sy sm ey em
  start_ym=$(grep -m1 'start:' "$CONFIG" | grep -oE '[0-9]{4}-[0-9]{2}')
  end_ym=$(grep -m1 'end:' "$CONFIG" | grep -oE '[0-9]{4}-[0-9]{2}')
  sy=${start_ym%-*}; sm=${start_ym#*-}
  ey=${end_ym%-*}; em=${end_ym#*-}
  echo $(( (10#$ey - 10#$sy) * 12 + (10#$em - 10#$sm) + 1 ))
}

N=${3:-$(default_n)}

# Cap on concurrently running load jobs (the array's %C). Set it to what your queue / fair-share allows.
# If N is smaller than the cap, use N; otherwise, use the cap.
MAX_CONCURRENT_LOADS=${MAX_CONCURRENT_LOADS:-48}
default_c() {
  echo $(( N < MAX_CONCURRENT_LOADS ? N : MAX_CONCURRENT_LOADS ))
}
C=$(default_c)

# Ensuring the data directory exists before submitting jobs
mkdir -p "$DATA_DIR"

echo "Config:  ${CONFIG}"
echo "Output:  ${OUTPUT}"
echo "Parts:   N=${N}  concurrency cap C=${C}"

# Submit the three stages of the parallel build as dependent jobs, so they run in order:
INIT_JOBID=$(sbatch --parsable \
  "$SCRIPT_DIR/build_hackathon_dataset_init.sh" "$CONFIG" "$OUTPUT")

LOAD_JOBID=$(sbatch --parsable --dependency=afterok:"$INIT_JOBID" \
  --array=1-"$N"%"$C" \
  "$SCRIPT_DIR/build_hackathon_dataset_load.sh" "$OUTPUT" "$N")

FINALISE_JOBID=$(sbatch --parsable --dependency=afterok:"$LOAD_JOBID" \
  "$SCRIPT_DIR/build_hackathon_dataset_finalise.sh" "$OUTPUT")

echo ""
echo "Submitted: init=${INIT_JOBID}  load(array)=${LOAD_JOBID}  finalise=${FINALISE_JOBID}"
echo ""
echo "Monitor:"
echo "  squeue -u \$USER"
echo "  sacct -j ${LOAD_JOBID} --format=JobID,JobName,State,ExitCode"
echo ""
echo "Logs: slurm-<jobid>.out in the submission directory, unless you set --output in the job scripts"
echo "  init=${INIT_JOBID}  load=${LOAD_JOBID}_<task>  finalise=${FINALISE_JOBID}"
