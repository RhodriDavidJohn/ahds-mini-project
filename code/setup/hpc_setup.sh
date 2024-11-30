#!/bin/bash

# create the conda environment
source ~/initConda.sh

CONDA_SUBDIR=linux-64 conda env create -n ahds-summative-env --file environment.yml

# activate the environment
conda activate ahds-summative-env


# save the slurm config document to home directory
mkdir -p ~/.config/snakemake/ahds_slurm_profile

cp code/setup/slurm_config.yaml ~/.config/snakemake/ahds_slurm_profile/config.yaml
