#!/bin/bash
#SBATCH --time 04:00:00
#SBATCH --account nct_389
#SBATCH --qos acc_training
#SBATCH --reservation PracticalActivities_4_ACC
#SBATCH --job-name hackathon-jupyterlab
#SBATCH --output /gpfs/home/nct/%u/logs/%x-%j.out
#SBATCH --error /gpfs/home/nct/%u/logs/%x-%j.err
#SBATCH --ntasks 1
#SBATCH --cpus-per-task 20
#SBATCH --gres gpu:1

set -euo pipefail

port=$((20000 + SLURM_JOB_ID % 20000))
node=$(hostname -s)
token=$(openssl rand -hex 24)

echo "JupyterLab job ${SLURM_JOB_ID} is running on ${node}."
echo
echo "From a NEW terminal on your LOCAL machine, run:"
echo "  ssh -N -o ExitOnForwardFailure=yes -L ${port}:${node}:${port} ${USER}@alogin1.bsc.es"
echo
echo "Keep that terminal open, then open this URL in your browser:"
echo "  http://localhost:${port}/lab?token=${token}"
echo

# Activate the shared .venv and point cartopy at the pre-fetched Natural Earth cache.
source /gpfs/projects/nct_389/climate-data-ai-anemoi/.venv/bin/activate
export CARTOPY_DATA_DIR=/gpfs/projects/nct_389/data/cartopy

jupyter lab --no-browser --port="$port" --ip="$node" --IdentityProvider.token="$token" --ServerApp.port_retries=0
