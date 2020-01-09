#!/bin/bash

find . -type f -exec cat {} + > ./combined.csv 
for value in {1..2}
do
    csv_line=`sed "${value}q;d" ./combined.csv`
    repository=$(echo ${csv_line} | cut -d',' -f1)
    echo "${repository}"
    find -name "${repository}.csv" -exec rm -f {} +
done

