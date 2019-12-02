#!/bin/bash
SOURCE_PATH=/home/worker/GG31_SYSTEM
source ${SOURCE_PATH}/etc/common.sh

function_eth0_hwaddr(){
	eth0_hwaddr=$(ifconfig eth0 |grep -i hwaddr |awk '{print $5}')
}

function_progress_bar(){
	# progress bar : $1 x 100 seconds
	printf "Waiting $1*100 seconds\n"
	local i=0 index=0 
	local str=""
	array=("|" "/" "-" "\\")
	for i in {0..100}
	do
		let index%=4
		printf "${C_B_GREEN} Progress: [%d%%]${C_F_RES} [%-100s] [\E[1;3${index}m%c${C_F_RES}]\r" "$i" "$str" "${array[$index]}"
		sleep $1
		let i++
		let index++
		str+='#'
	done
	printf "\n"
}

function_video0_lock_status(){
	# get video0 node lock status
	sudo i2cset -f -y 2 0x3d 0x4C 0x01
	port0_lock_sts=`sudo i2cget -y 2 0x3d 0x4d`
	sudo i2cset -f -y 2 0x3d 0x4C 0x12
	port1_lock_sts=`sudo i2cget -y 2 0x3d 0x4d`
	sudo i2cset -f -y 2 0x3d 0x4C 0x24
	port2_lock_sts=`sudo i2cget -y 2 0x3d 0x4d`
	sudo i2cset -f -y 2 0x3d 0x4C 0x38
	port3_lock_sts=`sudo i2cget -y 2 0x3d 0x4d`
	((port0_lock_sts=${port0_lock_sts}&0x1))
	((port1_lock_sts=${port1_lock_sts}&0x1))
	((port2_lock_sts=${port2_lock_sts}&0x1))
	((port3_lock_sts=${port3_lock_sts}&0x1))
}

function_video1_lock_status(){
	# get video1 node lock status
	sudo i2cset -f -y 2 0x30 0x4C 0x01
	port4_lock_sts=`sudo i2cget -y 2 0x30 0x4d`
	sudo i2cset -f -y 2 0x30 0x4C 0x12
	port5_lock_sts=`sudo i2cget -y 2 0x30 0x4d`
	sudo i2cset -f -y 2 0x30 0x4C 0x24
	port6_lock_sts=`sudo i2cget -y 2 0x30 0x4d`
	sudo i2cset -f -y 2 0x30 0x4C 0x38
	port7_lock_sts=`sudo i2cget -y 2 0x30 0x4d`
	((port4_lock_sts=${port4_lock_sts}&0x1))
	((port5_lock_sts=${port5_lock_sts}&0x1))
	((port6_lock_sts=${port6_lock_sts}&0x1))
	((port7_lock_sts=${port7_lock_sts}&0x1))
}

function_cpu_status_info(){
	local cpu_info=$(echo "$1" |tail -1 |awk '{print $6}')
	local cpu_info_format=$(echo "$cpu_info" |tr -d "[]")
	# cpu0-5 info extraction
	cpu0_info=$(echo "${cpu_info_format}" |awk -F "," '{print $1}')
	cpu1_info=$(echo "${cpu_info_format}" |awk -F "," '{print $2}')
	cpu2_info=$(echo "${cpu_info_format}" |awk -F "," '{print $3}')
	cpu3_info=$(echo "${cpu_info_format}" |awk -F "," '{print $4}')
	cpu4_info=$(echo "${cpu_info_format}" |awk -F "," '{print $5}')
	cpu5_info=$(echo "${cpu_info_format}" |awk -F "," '{print $6}')
	# cpu0-5 rate extraction
	cpu0_rate=$(echo "${cpu0_info}" |awk -F "%" '{print $1}')
	cpu1_rate=$(echo "${cpu1_info}" |awk -F "%" '{print $1}')
	cpu2_rate=$(echo "${cpu2_info}" |awk -F "%" '{print $1}')
	cpu3_rate=$(echo "${cpu3_info}" |awk -F "%" '{print $1}')
	cpu4_rate=$(echo "${cpu4_info}" |awk -F "%" '{print $1}')
	cpu5_rate=$(echo "${cpu5_info}" |awk -F "%" '{print $1}')
	let cpu_all_rate=$cpu0_rate+$cpu1_rate+$cpu2_rate+$cpu3_rate+$cpu4_rate+$cpu5_rate
	# cpu0-5 freq extraction
	cpu0_freq=$(echo "${cpu0_info}" |awk -F "@" '{print $2}')
	cpu1_freq=$(echo "${cpu1_info}" |awk -F "@" '{print $2}')
	cpu2_freq=$(echo "${cpu2_info}" |awk -F "@" '{print $2}')
	cpu3_freq=$(echo "${cpu3_info}" |awk -F "@" '{print $2}')
	cpu4_freq=$(echo "${cpu4_info}" |awk -F "@" '{print $2}')
	cpu5_freq=$(echo "${cpu5_info}" |awk -F "@" '{print $2}')
}

function_gpu_status_info(){
	local gpu_info=$(echo "$1" |tail -1 | awk '{print $10}')
	gpu_rate=$(echo "${gpu_info}" |awk -F "%" '{print $1}')
	gpu_freq=$(echo "${gpu_info}" |awk -F "@" '{print $2}')
}

function_temp_status_info(){
	local temp_info=$(echo "$1" |tail -1)
	temp_bcpu_info=$(echo "$temp_info" |awk '{print $18}')
	temp_bcpu=$(echo "$temp_bcpu_info" |awk -F "@" '{print $2}'|awk -F "C" '{print $1}')
	temp_mcpu_info=$(echo "$temp_info" |awk '{print $19}')
	temp_mcpu=$(echo "$temp_mcpu_info" |awk -F "@" '{print $2}'|awk -F "C" '{print $1}')
	temp_gpu_info=$(echo "$temp_info" |awk '{print $20}')
	temp_gpu=$(echo "$temp_gpu_info" |awk -F "@" '{print $2}'|awk -F "C" '{print $1}')
	temp_pll_info=$(echo "$temp_info" |awk '{print $21}')
	temp_pll=$(echo "$temp_pll_info" |awk -F "@" '{print $2}'|awk -F "C" '{print $1}')
	temp_tboard_info=$(echo "$temp_info" |awk '{print $23}')
	temp_tboard=$(echo "$temp_tboard_info" |awk -F "@" '{print $2}'|awk -F "C" '{print $1}')
	temp_tdiode_info=$(echo "$temp_info" |awk '{print $23}')
	temp_tdiode=$(echo "$temp_tdiode_info" |awk -F "@" '{print $2}'|awk -F "C" '{print $1}')
	temp_thermal_info=$(echo "$temp_info" |awk '{print $25}')
	temp_thermal=$(echo "$temp_thermal_info" |awk -F "@" '{print $2}'|awk -F "C" '{print $1}')
}

function_version_info(){
	version_hw_platform=$(uname -i)
	version_hw_kernal=$(uname -r)
	version_sw_os=$(jq -r '.version' ${F_P_RELEASE})
	version_sw_apu=$(jq -r '.MOD_hw_info.apu' ${F_P_RELEASE})
}

