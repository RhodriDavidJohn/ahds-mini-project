#!/bin/bash

#SBATCH --account=SSCM033324
#SBATCH --job-name=ahds_summative_setup
#SBATCH --partition=teach_cpu
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --time=00:10
#SBATCH --mem=1K

echo "Setting up HCP environment and pipeline slurm config"
bash code/setup/hpc_setup.sh
echo "Finished setup!"
