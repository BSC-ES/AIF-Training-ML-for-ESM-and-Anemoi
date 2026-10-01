#!/bin/bash
#SBATCH --job-name=hackathon-train
#SBATCH --time=02:00:00
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --gres=gpu:1   # one GPU; adapt to your cluster's syntax
#SBATCH --cpus-per-task=20
# Add the settings your cluster needs, for example:
##SBATCH --account=<your-project-account>
##SBATCH --qos=<queue-for-gpu-jobs>
##SBATCH --output=<log-dir>/%x-%j.out
##SBATCH --error=<log-dir>/%x-%j.err

# Train an anemoi model on one GPU. Adapt the #SBATCH lines to your cluster, or run the commands below
# directly on a machine with a GPU.
#
# Step 1 -- build the graph. It needs no GPU and no scheduler: run it from a terminal, from the repo root.
# The output path must match `system.input.graph` in configs/hackathon/hackathon_forecast.yaml:
#
#   anemoi-graphs create configs/hackathon/graph/hackathon_o96.yaml \
#       path/to/output/folder/training/graphs/hackathon_o96.pt --overwrite
#   anemoi-graphs describe path/to/output/folder/training/graphs/hackathon_o96.pt
#
# `describe` does not show whether every data node reaches the hidden mesh. Check it before training:
#
#   python -c "
#   import torch
#   g = torch.load('path/to/output/folder/training/graphs/hackathon_o96.pt', weights_only=False)
#   e = g['data', 'to', 'hidden'].edge_index
#   print('data nodes without an encoder edge:', int((torch.bincount(e[0], minlength=g['data'].num_nodes) == 0).sum()))"
#
# Step 2 -- train (this script). Anything after the config name is passed to Hydra as an override:
#
#   sbatch scripts/hackathon-training/train_hackathon.sh
#   sbatch scripts/hackathon-training/train_hackathon.sh configs/hackathon hackathon_forecast training.max_steps=100

set -euo pipefail

CONFIG_DIR=$(realpath "${1:-configs/hackathon}")
CONFIG_NAME=${2:-hackathon_forecast}
OVERRIDES=("${@:3}")

echo "Job started: $(date)"
echo "Config:      ${CONFIG_DIR}/${CONFIG_NAME}.yaml"
echo "Overrides:   ${OVERRIDES[*]:-none}"

# Activate the Python environment with the anemoi packages
# source path/to/.venv/bin/activate

# Full Hydra tracebacks instead of the one-line summary (the random seed defaults to the SLURM job id)
export HYDRA_FULL_ERROR=1

# anemoi-training looks for the config (and its local graph/, training/ groups) in the current directory
cd "$CONFIG_DIR"

# Fails in seconds on typos or wrong keys, before any data or GPU is touched
anemoi-training config validate --config-name "$CONFIG_NAME"

srun anemoi-training train --config-name="$CONFIG_NAME" "${OVERRIDES[@]}"

echo "Job finished: $(date)"
