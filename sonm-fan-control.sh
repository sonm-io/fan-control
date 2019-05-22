#!/usr/bin/env bash

# Exit script as soon as a command fails.
set -o errexit

# Executes cleanup function at script exit.
trap cleanup EXIT

export $(cat /etc/sonm/fan-control.txt)
export DISPLAY=:0
CARDS_NUM=`nvidia-smi -L | wc -l`
DELAY=5

cleanup() {
    for ((i=0; i<$CARDS_NUM; i++)); do
		nvidia-settings -a [gpu:$i]/GPUFanControlState=0
	done
}


if [[ "$(id -u)" != "0" ]]; then
   echo "This script must be run as superuser"
   exit 1
fi

if ! lspci -nm | grep '"\(0300\|0302\)" "10de"' 2>&1 >/dev/null; then
    echo "No NVIDIA GPUs detected"
    exit 0
fi

echo "Found ${CARDS_NUM} GPU(s) : MIN ${MIN_TEMP}°C - ${MAX_TEMP}°C MAX : Delay ${DELAY}s"

for ((i=0; i<$CARDS_NUM; i++)); do
	nvidia-settings -a [gpu:$i]/GPUFanControlState=1 2>&1 1>/dev/null
	if [ "$?" -ne 0 ]; then
		exit 1;
	fi
done

echo "GPUFanControlState set to 1 for all cards"

while true; do
	for ((i=0; i<$CARDS_NUM; i++)); do
		GPU_TEMP=`nvidia-smi -i $i --query-gpu=temperature.gpu --format=csv,noheader`
		if [[ $GPU_TEMP -lt $MIN_TEMP ]]; then
			FAN_SPEED=0
		elif [[ $GPU_TEMP -gt $MAX_TEMP ]]; then
			FAN_SPEED=100
		else
			FAN_SPEED=$(( ($GPU_TEMP - $MIN_TEMP)*100/($MAX_TEMP - $MIN_TEMP) ))
		fi
		nvidia-settings -a [fan:$i]/GPUTargetFanSpeed=$FAN_SPEED 2>&1 1>/dev/null
		echo "GPU${i} ${GPU_TEMP}°C, fan -> ${FAN_SPEED}%"
	done
	sleep $DELAY
done
