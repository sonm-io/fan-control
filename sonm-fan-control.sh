#!/usr/bin/env bash

VERSION="0.2.1"

# Executes cleanup function at script exit.
trap cleanup EXIT

cleanup() {
    for ((i=0; i<$CARDS_NUM; i++)); do
    	echo "INFO: Exit. Transfer fan control to driver."
		nvidia-settings -a [gpu:$i]/GPUFanControlState=0
	done
}

init() {
	echo "Sonm-fan-control service, version ${VERSION}"
	if [[ "$(id -u)" != "0" ]]; then
	   echo "ERROR: This script must be run as superuser"
	   exit 1
	fi

	if ! lspci -nm | grep '"\(0300\|0302\)" "10de"' 2>&1 >/dev/null; then
	    echo "ERROR: No NVIDIA GPUs detected"
	    exit 0
	fi

	export DISPLAY=:0
	reload_config
	CARDS_NUM=`nvidia-smi -L | wc -l`
	DELAY=5

	echo "INFO: Found ${CARDS_NUM} GPU(s)"
	echo $(print_config)

	for ((i=0; i<$CARDS_NUM; i++)); do
		nvidia-settings -a [gpu:$i]/GPUFanControlState=1 1>/dev/null
		if [ "$?" -ne 0 ]; then
			echo "ERROR: Cannot take control of the GPU fans. Exit"
			exit 1
		fi
	done

	echo "INFO: GPUFanControlState set to 1 for all cards"
}

print_config() {
	echo "INFO: Settings: TEMP: Min ${MIN_TEMP}°C, Max ${MAX_TEMP}°C, Critical ${CRIT_TEMP}°C; Min fan speed ${MIN_FAN_SPEED}% : Delay ${DELAY}s"
}

reload_config() {
	export $(cat /etc/sonm/fan-control.txt | grep -v "#")
	if [[ -z $SETTINGS_TS ]]; then
		SETTINGS_TS=$(date +%s)
	fi
	CONFIG_CHANGE_TS=$(stat /etc/sonm/fan-control.txt --format='%Y')
	if [[ $CONFIG_CHANGE_TS -gt $SETTINGS_TS ]]; then
		echo "INFO: Detected config change"
		echo $(print_config)
		SETTINGS_TS=$(date +%s)
	fi

	# check config
	if [[ $MIN_TEMP -ge $MAX_TEMP ]]; then
		echo "ERROR: Configuration error, MIN_TEMP>=MAX_TEMP"
		exit 1
	elif [[ $MAX_TEMP -ge $CRIT_TEMP ]]; then
		echo "ERROR: Configuration error, MAX_TEMP>=CRIT_TEMP"
		exit 1
	elif [[ $MIN_FAN_SPEED -lt 0 ]]; then
		echo "ERROR: Configuration error, MIN_FAN_SPEED<=0"
		exit 1
	elif [[ $MIN_FAN_SPEED -gt 100 ]]; then
		echo "ERROR: Configuration error, MIN_FAN_SPEED>=100"
		exit 1
	fi

	return 0
}

get_gpu_temp() {
		local temp=$(nvidia-smi -i $1 --query-gpu=temperature.gpu --format=csv,noheader)
		ERR=$?

		if ! [[ $ERR -eq 0 ]]; then
			echo "INFO:" $(nvidia-smi -L)
			echo "CRITICAL: Cannot get temp for GPU${1}. Seems like GPU is lost. Forcing reboot"
			reboot
		fi

		if [[ $temp -gt $CRIT_TEMP ]]; then
			echo "CRITICAL: GPU${1} exceeded critical temp. Forcing reboot"
			reboot
		fi

		echo $temp
}

init

while true; do
	for ((i=0; i<$CARDS_NUM; i++)); do
		GPU_TEMP=$(get_gpu_temp $i)

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
	reload_config
done
