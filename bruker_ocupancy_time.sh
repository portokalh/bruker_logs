#!/bin/bash

echo
echo "BRUKER UTILIZATION REPORT — JUNE 2026"
echo "=========================================================="
printf "%-10s  %-5s  %-5s  %10s  %11s\n" \
       "DATE" "FIRST" "LAST" "NOMINAL_H" "OCCUPANCY_H"
echo "----------------------------------------------------------"

total_nominal=0
total_occupancy=0

for d in $(find . -maxdepth 1 -type d \
    -name '202606??_??????_*' \
    -printf '%f\n' |
    cut -d_ -f1 |
    sort -u); do

    studies=$(find . -maxdepth 1 -type d \
        -name "${d}_??????_*" \
        -printf '%f\n' |
        sort)

    first=$(printf "%s\n" "$studies" | head -1)
    last=$(printf "%s\n" "$studies" | tail -1)

    firsttime=$(printf "%s\n" "$first" | cut -d_ -f2)
    lasttime=$(printf "%s\n" "$last" | cut -d_ -f2)

    first_epoch=$(date -d \
        "${d:0:4}-${d:4:2}-${d:6:2} ${firsttime:0:2}:${firsttime:2:2}:${firsttime:4:2}" \
        +%s)

    last_epoch=$(date -d \
        "${d:0:4}-${d:4:2}-${d:6:2} ${lasttime:0:2}:${lasttime:2:2}:${lasttime:4:2}" \
        +%s)

    day_ms=$(find . -maxdepth 1 -type d \
        -name "${d}_??????_*" -print0 |
        xargs -0 -I{} find "{}" -name method -print0 2>/dev/null |
        xargs -0 awk -F= '
        /^##\$PVM_ScanTime=/ {
            ms += $2
        }
        END {
            printf "%.0f", ms
        }')

    last_ms=$(find "./$last" -name method -print0 2>/dev/null |
        xargs -0 awk -F= '
        /^##\$PVM_ScanTime=/ {
            ms += $2
        }
        END {
            printf "%.0f", ms
        }')

    day_ms=${day_ms:-0}
    last_ms=${last_ms:-0}

    nominal_h=$(awk -v ms="$day_ms" \
        'BEGIN {printf "%.2f", ms/3600000}')

    occupancy_h=$(awk \
        -v a="$first_epoch" \
        -v b="$last_epoch" \
        -v ms="$last_ms" \
        'BEGIN {printf "%.2f", (b-a)/3600 + ms/3600000}')

    printf "%-10s  %s:%s  %s:%s  %10.2f  %11.2f\n" \
        "$d" \
        "${firsttime:0:2}" "${firsttime:2:2}" \
        "${lasttime:0:2}" "${lasttime:2:2}" \
        "$nominal_h" \
        "$occupancy_h"

    total_nominal=$(awk \
        -v t="$total_nominal" \
        -v h="$nominal_h" \
        'BEGIN {printf "%.6f", t+h}')

    total_occupancy=$(awk \
        -v t="$total_occupancy" \
        -v h="$occupancy_h" \
        'BEGIN {printf "%.6f", t+h}')
done

productive_nominal=$(awk -v t="$total_nominal" \
    'BEGIN {printf "%.2f", t-3}')

productive_occupancy=$(awk -v t="$total_occupancy" \
    'BEGIN {printf "%.2f", t-3}')

echo "=========================================================="
printf "%-40s %8.2f h\n" \
    "Total nominal acquisition time:" "$total_nominal"

printf "%-40s %8.2f h\n" \
    "Estimated scanner occupancy:" "$total_occupancy"

printf "%-40s %8.2f h\n" \
    "Nominal time excluding ~3 h debugging:" "$productive_nominal"

printf "%-40s %8.2f h\n" \
    "Occupancy excluding ~3 h debugging:" "$productive_occupancy"

echo "=========================================================="
echo
EOF
