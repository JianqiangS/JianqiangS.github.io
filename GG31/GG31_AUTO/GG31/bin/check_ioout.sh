#!/bin/bash
SOURCE_PATH=/home/worker/GG31
source ${SOURCE_PATH}/etc/common.sh
source ${SOURCE_PATH}/etc/function.sh

check_ioout_function(){
	# check master io_external contain u_disk & hard_disk function
	function_lever_second_master "$1 mounted route path"
	df -ahl |grep $1
	function_lever_second_master "$1 mounted route path file list"
	sleep 1 && ls -lh $2
	function_lever_second_master "$1 write function"
	printf "${C_F_LINE}Before write : list $2 file${C_F_RES}\n"
	ls -lh $2
	sudo cp -r /etc $2
	if [ "$?" -eq 0 ]
	then
		printf "\n${C_F_LINE}After write : list $2 file${C_F_RES}\n"
		ls -lh $2
		printf "Write $1 $2 success ...\n"
	else
		printf "Write $1 $2 failed ...\n"
	fi
	function_lever_second_master "$1 read function"
	printf "${C_F_LINE}Before read : list ${r_p_log} file${C_F_RES}\n" 
	ls -lh ${r_p_log}
	sudo cp -r $2/etc ${r_p_log}
	if [ "$?" -eq 0 ]
	then 
		printf "\n${C_F_LINE}After read : list ${r_p_log} file${C_F_RES}\n"
		ls -lh ${r_p_log}
		printf "Read $1 $2 success ...\n"
		sudo rm -rf ${r_p_log}/etc
	else
		printf "Read $1 $2 failed ...\n"
	fi
	echo "${S_L_STR0// /-}"
}

check_ioout_udisk(){
	function_lever_first_master "ioout u_disk"
	local ioout_udisk_type=$(jq -r ".para_ioout.ioout_udisk_type" ${SOURCE_PATH}/config.json)
	local ioout_udisk_mounted=$(jq -r ".para_ioout.ioout_udisk_mounted" ${SOURCE_PATH}/config.json)
	if [ -b "${ioout_udisk_type}" ]
	then
		if [ -d "${ioout_udisk_mounted}" ]
		then
			check_ioout_function ${ioout_udisk_type} ${ioout_udisk_mounted}
		else
			printf "${C_F_LINE}[ Check ] : ${SOURCE_PATH}/config.json ioout_udisk_mounted error ${C_F_RES}\n"
		fi
	else
		printf "${C_F_LINE}[ Check ] : ${SOURCE_PATH}/config.json ioout_udisk_type error ${C_F_RES}\n"
	fi
	echo "${STR// /-}"
}

check_ioout_harddisk(){
	function_lever_first_master "ioout hard_disk"
	local ioout_harddisk_type=$(jq -r ".para_ioout.ioout_harddisk_type" ${SOURCE_PATH}/config.json)
	local ioout_harddisk_mounted=$(jq -r ".para_ioout.ioout_harddisk_mounted" ${SOURCE_PATH}/config.json)
	if [ -b "${ioout_harddisk_type}" ]
	then
		if [ -d "${ioout_harddisk_mounted}" ]
		then
			check_ioout_function ${ioout_harddisk_type} ${ioout_harddisk_mounted}
		else
			printf "${C_F_LINE}[ Check ] : ${SOURCE_PATH}/config.json ioout_harddisk_mounted error ${C_F_RES}\n"
		fi
	else
		printf "${C_F_LINE}[ Check ] : ${SOURCE_PATH}/config.json ioout_harddisk_type error ${C_F_RES}\n"
	fi
	echo "${STR// /-}"
}

check_ioout(){
	# check ioout module
	check_ioout_harddisk
	check_ioout_udisk
}
