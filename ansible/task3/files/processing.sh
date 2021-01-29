#!/bin/bash

bucket="$1"

while : ;do
    for file in "${bucket}/in/"*; do
        if [[ -f "$file" ]]; then
            for i in $(cat $file | cut -d\: -f1-3); do
                echo "$(date);DONE;$i" >> "${bucket}/out/$(basename $file)"
            done
            rm -f "$file"
        fi
    done
    sleep 1
done