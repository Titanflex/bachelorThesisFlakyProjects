#!/bin/bash

SLURM_JOB_ID=0
PID=$$

function sig_handler {
  echo "Canceling the SLURM job..."
  if [[ "$SLURM_JOB_ID" -gt 0 ]]
  then
    scancel "${SLURM_JOB_ID}"
  fi

  echo "Killing the $0 including its childs..."
  pkill -TERM -P ${PID}

  echo -e "Terminated: $0\n"
}
trap sig_handler INT TERM HUP QUIT

IFS=',' read SLURM_JOB_ID rest < <(sbatch --parsable array_flaky.sh)
if [ -z "${SLURM_JOB_ID}" ]
then
  echo "Submitting the SLURM job failed!"
  exit 1
fi

echo "SLURM job with ID ${SLURM_JOB_ID} submitted!"
total=1
# periodically look for jobs pending/running
while [ "${total}" -gt 0 ]; do
  pending=$(squeue --noheader --array -j "${SLURM_JOB_ID}" -t PD | wc -l)
  running=$(squeue --noheader --array -j "${SLURM_JOB_ID}" -t R | wc -l)
  total=$(squeue --noheader --array -j "${SLURM_JOB_ID}" | wc -l)
  echo "Job ${SLURM_JOB_ID}: ${total} runs found (${pending} pending, ${running} running) of ${numOfRuns} runs total"
  if [ "${total}" -gt 0 ]; then
    sleep 10
  fi
done

