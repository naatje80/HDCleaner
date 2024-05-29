#! /bin/bash

TIME=${1}
SIZE=${2}
MESSAGE=${3}

START_TIME=`date +%s`
TIME_DELTA=""

while [[ ${TIME} -gt ${TIME_DELTA} ]]
do
	sleep 0.2
	CURRENT_TIME=`date +%s`
	TIME_DELTA=$(( ${CURRENT_TIME} - ${START_TIME} ))
	PERCENTAGE=`echo "scale=4; ${TIME_DELTA} / ${TIME} * 100" | bc -l`
	RANGE=`echo "scale=0; ${SIZE} * ${PERCENTAGE} / 100"| bc -l`
	if [[ ${RANGE} -gt 0 ]]
	then
		PROGRESS=`sh -c "printf \"#%.0s\" {1..$RANGE}"`
	else
		PROGRESS=""
	fi
	printf "\r%s: [%-${SIZE}s] %.0f%%" "${MESSAGE}" "${PROGRESS}" ${PERCENTAGE}	
done
