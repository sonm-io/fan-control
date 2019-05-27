#!/usr/bin/env bash

# Executes cleanup function at script exit.
trap cleanup EXIT

export $(cat /etc/sonm/fan-control.txt)
export DISPLAY=:0
CARDS_NUM=`nvidia-smi -L | wc -l`
DELAY=5

cleanup() {
    for ((i=0; i<$CARDS_NUM; i++)); do
    	echo "INFO: Exit. Setting fan speed for GPU${i} to 100%"
    	nvidia-settings -a [fan:$i]/GPUTargetFanSpeed=100 1>/dev/null
		nvidia-settings -a [gpu:$i]/GPUFanControlState=0
	done
}


if [[ "$(id -u)" != "0" ]]; then
   echo "ERROR: This script must be run as superuser"
   exit 1
fi

if ! lspci -nm | grep '"\(0300\|0302\)" "10de"' 2>&1 >/dev/null; then
    echo "ERROR: No NVIDIA GPUs detected"
    exit 0
fi

echo "INFO: Found ${CARDS_NUM} GPU(s)"
echo "INFO: Settings: TEMP: Min ${MIN_TEMP}°C, Max ${MAX_TEMP}°C, Critical ${CRIT_TEMP}°C; Min fan speed ${MIN_FAN_SPEED}% : Delay ${DELAY}s"

for ((i=0; i<$CARDS_NUM; i++)); do
	nvidia-settings -a [gpu:$i]/GPUFanControlState=1 1>/dev/null
	if [ "$?" -ne 0 ]; then
		exit 1
	fi
done

echo "INFO: GPUFanControlState set to 1 for all cards"

while true; do
	for ((i=0; i<$CARDS_NUM; i++)); do
		GPU_TEMP=`nvidia-smi -i $i --query-gpu=temperature.gpu --format=csv,noheader`
		if [[ $GPU_TEMP -gt $CRIT_TEMP ]]; then
			echo "CRITICAL: GPU${i} exceeded critical temp, forcing reboot"
			reboot
		fi
		if [[ $GPU_TEMP -lt $MIN_TEMP ]]; then
			FAN_SPEED=$MIN_FAN_SPEED
		elif [[ $GPU_TEMP -gt $MAX_TEMP ]]; then
			echo "WARN: GPU${i} temp ${GPU_TEMP}°C"
			FAN_SPEED=100
		else
			FAN_SPEED=$(( $MIN_FAN_SPEED + ($GPU_TEMP - $MIN_TEMP)*(100 - $MIN_FAN_SPEED)/($MAX_TEMP - $MIN_TEMP) ))
		fi
		echo "INFO: GPU${i} ${GPU_TEMP}°C, fan -> ${FAN_SPEED}%"
		nvidia-settings -a [fan:$i]/GPUTargetFanSpeed=$FAN_SPEED 1>/dev/null
	done
	sleep $DELAY
done
