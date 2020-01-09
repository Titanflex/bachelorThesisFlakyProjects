#!/bin/bash

while IFS=, read -r field1; do
    echo "${field1}.csv"
    if [ ! -f ./"${field1}.csv" ]; then
        echo "File not found"
    else
        find . -name "${field1}.csv" -exec rm -f {} + 
    fi
done < <(cat combined.csv | tr -d "\r")

