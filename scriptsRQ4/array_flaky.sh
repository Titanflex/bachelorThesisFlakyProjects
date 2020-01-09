#!/bin/bash
#SBATCH --partition=anywhere
#SBATCH --constraint=pontipine
#SBATCH --job-name=flakyanalysis
#SBATCH --time=02:00:00
#SBATCH --mem=16GB
#SBATCH --nodes=1-1
#SBATCH --ntasks=1
#SBATCH --array=1-1943


n=${SLURM_ARRAY_TASK_ID}
csv_line=`sed "${n}q;d" /scratch/grelka/scriptsRQ4/repos.csv`

repository=$(echo ${csv_line} | cut -d',' -f1)
repository_url=$(echo ${csv_line} | cut -d',' -f2)
commit_hash=$(echo ${csv_line} | cut -d',' -f3)
if [ -z "$commit_hash" ]; then
    commit_hash="00000"
    echo "No commit_hash"
fi

echo "Run Jobs for ${repository}"
echo "URL ${repository_url}"
echo "Hash ${commit_hash}"

function sighdl {
  kill -INT "${srunPid}" || true
}

mkdir -p /scratch/grelka/authors/run
outfile="/scratch/grelka/authors/run/${repository}-out.txt"
errfile="/scratch/grelka/authors/run/${repository}-err.txt"

srun \
  --user-cgroups=on \
  --output=$outfile \
  --error=$errfile \
  "./run_flaky.sh" "${repository}" "${repository_url}" "${commit_hash}" \
  & srunPid=$!
  
trap sighdl INT TERM HUP QUIT

while ! wait; do true; done
