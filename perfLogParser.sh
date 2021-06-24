#!/bin/bash

perfLogs="$1"    # file containing the entire log of the performance run 

# CREATE_TIME=`date +"%Y-%m-%d-%H.%M.%S.%3N"`
# DATE_TIME=`echo "$CREATE_TIME" | tr '-' '_' | tr '.' '_'`

perfResults="${PARSED_RESULT}"      # file to output the parsed results

# NAME="name"
# PARSETIME="parsingTime"
# ANALYSISTIME="analysisTime"
# OPTIMIZETIME="optimizationTime"
# PLANTIME="planningTime"
# EXECUTETIME="executionTime"

# An map of field names to their column number
declare -A fields=( [NAME]=1 [PARSETIME]=6 [ANALYSISTIME]=7 [OPTIMIZETIME]=8 [PLANTIME]=9 [EXECUTETIME]=10 )

resultFields=( "NAME" "PARSETIME" "ANALYSISTIME" "OPTIMIZETIME" "PLANTIME" "EXECUTETIME" "TOTALTIME" )


# Takes in one line in the tpch result table and parses the results into the row map
function parseFields()
{
    # A map to hold one entry of the tpch results
    # e.g. Results for Q1 could stored as:
    # row=( [NAME]="Q1" [PARSETIME]=0.013846 [ANALYSISTIME]=0.005296 [OPTIMIZETIME]=13.196243 [PLANTIME]=7.758993 [EXECUTETIME]=1465991.934874 )
    declare -A row
    local line="$1"
    local entryNum=$2

    line=$( echo ${line} | tr -d " " | tr "|" " " )
    # echo $line

    for field in ${!fields[@]}; do
        row[${field}]+=$( echo $line | awk "{print \$${fields[$field]}}" )
    done

    # Calculate total time, we are ignoring values with "E-". They are insignificantly small.
    local totalTime=0
    for field in ${!fields[@]}; do
        if [[ ${field} != "NAME" ]]; then
            [[ "${row[${field}]}" == *"E-"* ]] && continue
            totalTime=$( echo - | awk "{printf \"%f\", ${totalTime} + ${row[${field}]}}" )
        fi
    done
    row[TOTALTIME]+=$totalTime

    echo "" >> "${perfResults}"
    for field in ${resultFields[@]}; do
        echo $field: ${row[$field]} >> "${perfResults}"
    done

    # clear the map for the next entry in the tpch results
    unset row
}

printf "%-24s %s\n" TIME: "${CI_JOB_STARTED_AT}" >> "${perfResults}"
printf "%-24s %s\n" JOB: "${JOB}" >> "${perfResults}"
printf "%-24s %s\n" SPARK_IMAGE: "${SPARK_IMAGE}" >> "${perfResults}"
printf "%-24s %s\n" SPARK_DRIVER_MEMORY: "${SPARK_DRIVER_MEMORY}" >> "${perfResults}"
printf "%-24s %s\n" SPARK_EXECUTOR_MEMORY: "${SPARK_EXECUTOR_MEMORY}" >> "${perfResults}"
printf "%-24s %s\n" CACHE_SSD_SIZE: "${CACHE_SSD_SIZE}" >> "${perfResults}"
printf "%-24s %s\n" SPARK_SQL_PERF_JAR: "${SPARK_SQL_PERF_JAR}" >> "${perfResults}"
printf "%-24s %s\n" ALLUXIO_VERSION: "${ALLUXIO_VERSION}" >> "${perfResults}"
printf "%-24s %s\n\n" SPARK_DRIVER_POD_NAME: "${SPARK_DRIVER_POD_NAME}" >> "${perfResults}"

# Filter out all the log messages except for the table containing the final results
cat "$perfLogs" | grep -oPz '(?s)\+---.*---\+' | tr -d '\000' >> "${perfResults}"
echo "" >> "${perfResults}"


entryNum=0

# read through the tpch result table line by line
while IFS= read -r line
do
  # ignore lines that start with "+" since they are just visual boundaries
  if [[ "${line}" == "|"* ]]; then
    # ignore the header row
    [[ $entryNum -eq 0 ]] && (( entryNum+=1 )) && continue
    parseFields "${line}" $entryNum
    (( entryNum+=1 ))
  fi
done < "${perfResults}"


# remove this later
cat "${perfResults}"
