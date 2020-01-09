#!/bin/bash

DEBUG=1

function debugecho {
  [ "${DEBUG}" = 1 ] && echo "$@"
}

start=`date +%s`

cwd=$(pwd)
repository=$1
repository_url=$2
commit_hash=$3
installed_python="/usr/bin/python3"
scratch_python="/scratch/grelka/Python-3.7.4/bin/python3.7"
local_dir="/local/hdd/grelka/${repository}"
scratch_dir="/scratch/grelka"
base_dir="${scratch_dir}/authors"
scratch_testauthors_dir="${scratch_dir}/testauthors"
analysis_directory="/scratch/grelka/flakyanalysis/results"
testline_directory="/scratch/grelka/flakyanalysis/testplan"

debugecho "Project ${repository}"
mkdir -p ${local_dir}


export HOME=$local_dir

debugecho "Copy TestAuthors to local file system"
if [ ! -d "${local_dir}/testauthors" ]
then
  cp -R "${scratch_testauthors_dir}" "${local_dir}"
fi

mkdir -p "${local_dir}/authors"
mkdir -p "${base_dir}/lessflakyauthors"
mkdir -p "${base_dir}/moreflakyauthors"
mkdir -p "${base_dir}/samenumberofauthors"
mkdir -p "${base_dir}/incomplete/notestcasefile"
mkdir -p "${base_dir}/incomplete/noflakytestfile"
mkdir -p "${base_dir}/notflaky"


debugecho "Change directory to local TestAuthors"
cd "${local_dir}/testauthors"

debugecho "Create virtualenv"
virtualenv -p "${scratch_python}" "../testauthors-venv-${repository}"

source "../testauthors-venv-${repository}/bin/activate"

debugecho "Install dependencies"
pip install --no-cache-dir \
  plumbum \
  peewee \
  requests \
  bs4 \
  pygithub \
  virtualenv \
  pipfile \
  gitpython \
  pydriller \
  benchexec \
  configargparse

debugecho "Using Python version $(python --version) in $(which python)"

debugecho "Creating TMP Directory for Runner venv"
mkdir -p "${local_dir}/authors/${repository}/venv"

debugecho "Checkout repository"
repository_dir="${local_dir}/authors/${repository}/${repository}"
git clone $repository_url $repository_dir

cd "${local_dir}/testauthors"

mkdir "${local_dir}/testauthors/all_tests"
mkdir "${local_dir}/testauthors/flaky_tests"

cp "${testline_directory}/${repository}.csv" "${local_dir}/testauthors/all_tests"
cd "${analysis_directory}"
find -type f -name "${repository}.csv" -exec cp {} "${local_dir}/testauthors/flaky_tests" \;
cd "${local_dir}/testauthors"

debugecho "Run Analysis"
python testauthors_analyzer.py \
  -l "${base_dir}/${repository}.log" \
  -r "${repository_dir}" \
  -u "${repository_url}" \
  -o "${base_dir}" \

debugecho "Deactivate virtualenv"
deactivate

cd ${cwd}

debugecho "Clean up"
rm -rf "${local_dir}/authors"
rm -rf "${local_dir}/testauthors-venv-${repository}"
rm -rf "${local_dir}/testauthors"
rm -rf "${local_dir}/.cache"
rm -rf "${local_dir}"

end=`date +%s`
runtime=$((end-start))
echo "" >> "${base_dir}/${repository}.log"
echo "" >> "${base_dir}/${repository}.log"
echo "Execution time: ${runtime}" >> "${base_dir}/${repository}.log"

debugecho "Done"
export HOME="/home/grelka"
