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
scratch_pydefects_dir="/scratch/grelka/pydefects"
local_dir="/local/hdd/grelka/${repository}"
scratch_dir="/scratch/grelka"
base_dir="${scratch_dir}/flakyanalysis"

debugecho "Project ${repository}"
mkdir -p ${local_dir}

mkdir ${scratch_dir}/flakycounter

cd "${base_dir}"
mkdir ./testplan
mkdir ./results
cd results
mkdir -p ./notflaky/smallprojects
mkdir -p ./notflaky/bigprojects
mkdir -p ./lessthanquarterflaky/smallprojects
mkdir -p ./lessthanquarterflaky/bigprojects
mkdir -p ./lessthanhalfflaky/smallprojects
mkdir -p ./lessthanhalfflaky/bigprojects
mkdir -p ./morethanhalfflaky/smallprojects
mkdir -p ./morethanhalfflaky/bigprojects

export HOME=$local_dir

debugecho "Copy PyDefects to local file system"
if [ ! -d "${local_dir}/pydefects" ]
then
  cp -R "${scratch_pydefects_dir}" "${local_dir}"
fi

mkdir -p "${local_dir}/flakyanalysis"

debugecho "Change directory to local PyDefects"
cd "${local_dir}/pydefects"

debugecho "Create virtualenv"
virtualenv -p "${scratch_python}" "../pydefects-venv-${repository}" --no-download

source "../pydefects-venv-${repository}/bin/activate"

debugecho "Install dependencies"
pip install --no-cache-dir \
  plumbum \
  pipreqs \
  peewee \
  requests \
  bs4 \
  pygithub \
  virtualenv \
  pipfile \
  gitpython \
  pydriller \
  benchexec==1.22 \
  configargparse 
  

debugecho "Using Python version $(python --version) in $(which python)"

debugecho "Creating TMP Directory for Runner venv"
mkdir -p "${local_dir}/flakyanalysis/${repository}/venv"

debugecho "Checkout repository"
repository_dir="${local_dir}/flakyanalysis/${repository}/${repository}"
git clone $repository_url $repository_dir
cd $repository_dir

echo $(pwd)
if [ "$commit_hash" != "00000" ]; then
    testhash=${commit_hash::-4}
    echo "$commit_hash --> $testhash"
    parent_hash=$(git log --pretty=%P -n 1 $testhash 2>&1)
    echo "TH ${testhash}"
    echo "PH ${parent_hash}"
    git reset --hard $parent_hash
    contained_test_files=$(find $directory_path -name "test*.py" | wc -l)
    if [ $contained_test_files = 0 ]; then
        echo "No testfiles available in Parent commit"
        git pull
    fi
fi
flakycounter=$(find . -name "*.py" -exec grep -rn "@flaky" {} \; | wc -l )
if [ $flakycounter -gt 0 ]; then
    echo "$flakycounter" > ${scratch_dir}/flakycounter/${repository}.txt
fi
echo "@flakycounter ${repository} ${flakycounter}"
find . -type f -name "conftest.py" -exec rm {} +
cp ${scratch_dir}/scriptsRQ1.1/conftest.py ./
pipreqs --force ./
#pip install -r ./requirements.txt
cd "${local_dir}/pydefects"


debugecho "Run Analysis"
python pydefects-flakyanalyser.py \
  -l "${base_dir}/${repository}.log" \
  -r "${repository_dir}" \
  -t "${local_dir}/flakyanalysis/${repository}/venv" \
  -b global \
  -o "${base_dir}/${repository}.txt" \
  -c "${base_dir}/results/" \
  -p "${base_dir}/testplan/"

debugecho "Deactivate virtualenv"
deactivate

cd ${cwd}

debugecho "Clean up"
rm -rf "${local_dir}/flakyanalysis"
rm -rf "${local_dir}/pydefects-venv-${repository}"
rm -rf "${local_dir}/pydefects"
rm -rf "${local_dir}/.cache"
rm -rf "${local_dir}"

end=`date +%s`
runtime=$((end-start))
echo "" >> "${base_dir}/${repository}.log"
echo "" >> "${base_dir}/${repository}.log"
echo "Execution time: ${runtime}" >> "${base_dir}/${repository}.log"

debugecho "Done"
export HOME="/home/grelka"
