#!/bin/bash

if [[ -z "$1" ]];
then
    echo "Usage: $(basename $0) <comma separated list-to combine and sort>"
    exit 1;
fi
COMMA_SEPARATED_LIST=$1

# Parse comma separated list into an array
IFS=',' read -ra ARR <<< "$COMMA_SEPARATED_LIST"
# Sort APP_NAMES array in alphabetical order, so that order does not matter when maintaining directories, states etc
SORTED_ARR=( $(for arr in "${ARR[@]}"
do
        echo $arr
done | sort) );

# join alphabetically ordered list by '-'
JOINED_LIST=$(IFS=- ; echo "${SORTED_ARR[*]}");

echo "$JOINED_LIST"