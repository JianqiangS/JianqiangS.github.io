#!/bin/bash
SOURCE_PATH=/home/worker/GG31
source ${SOURCE_PATH}/etc/common.sh
source ${SOURCE_PATH}/etc/function.sh

check_cdu_master_dsi(){
	# check cdu dsi function switch
	function_lever_first_master "cdu moduel dsi function switch"
	li=("slave" "dual" "master")
	for ((i=0;i<=2;i++))
	do
		function_lever_second_master "switch dsi ${li[$i]} mode"
		switch_gmsl.sh -m ${li[$i]} && sleep 15
		function_lever_second_master "${li[$i]} mode dsi status"
		ssh slave "sudo gmsl_i2c_op r 0x48 0x03"
	done
	echo "${S_L_STR0// /-}"
}

check_cdu_camera_status(){
	# statistics camera in-position status
	local vid0=$(grep -c video0 ${r_p_log}/diag_module.log)
	local vid1=$(grep -c video1 ${r_p_log}/diag_module.log)
	echo "${S_L_STR0// /-}"
	printf "Check video0 && video1 present status\n"
	cat ${r_p_log}/diag_module.log
	printf "${C_F_LINE} set cdu_video0_num ${cdu_video0_num} ; check cdu_video0_num : ${vid0}${C_F_RES}\n"
	printf "${C_F_LINE} set cdu_video1_num ${cdu_video1_num} ; check cdu_video1_num : ${vid1}${C_F_RES}\n"
	if [ ! "${vid0}" -eq "${cdu_video0_num}" ] || [ ! "${vid1}" -eq "${cdu_video1_num}" ]
	then
		printf "${SOURCE_PATH} para_cdu.cdu_video0_num or cdu_video1_num error\n"
		exit 1
	fi
	echo "${S_L_STR0// /-}"
}

check_cdu_master_status(){
	# check cdu master video status
	config_ub964.sh > ${r_p_log}/diag_module.log
	# master port cdu camera in-position status
	function_lever_first_master "camera in-position status"
	check_cdu_camera_status
	function_lever_first_master "dump image data"
	# check dump video0 data 
	function_lever_second_master "dump video0 image data"
	if [ "${cdu_video0_num}" -gt 0 ]
	then
		printf "Check dump video0 data...\n"
		timeout 10 dump_video0.sh -n ${cdu_video0_num}
		function_lever_second_master "dump video0 image data and check size"
		dump_video.sh -i 0 -n ${cdu_video0_num} -c 100 -s ${r_p_log}/video0.tgz   
		local video0_size=$(ls -lh ${r_p_log}/video0.tgz |awk '{print $5}')
		echo -e "${S_L_STR0// /-}\nvideo0.tgz size : ${video0_size}"
		rm -rf ${r_p_log}/video0.tgz
		function_lever_second_master "dump video0 image date ${cdu_dump_num} fps"
		dump_video.sh -i 0 -n ${cdu_video0_num} -c ${cdu_dump_num}
	else
		printf "${C_F_LINE}[ Check ] : video0 node connect ${cdu_video0_num} video${C_F_RES}\n"
	fi
	# check dump video1 data
	function_lever_second_master "dump video1 image data"
	if [ "${cdu_video1_num}" -gt 0 ]
	then
		printf "Check dump video1 data...\n"
		timeout 10 dump_video1.sh -n ${cdu_video1_num}
		function_lever_second_master "dump video1 image data and check size"
		dump_video.sh -i 1 -n ${cdu_video1_num} -c 100 -s ${r_p_log}/video1.tgz   
		local video1_size=$(ls -lh ${r_p_log}/video1.tgz |awk '{print $5}')
		echo -e "${S_L_STR0// /-}\nvideo1.tgz size : ${video1_size}"
		rm -rf ${r_p_log}/video1.tgz
		function_lever_second_master "dump video1 image date ${cdu_dump_num} fps"
		dump_video.sh -i 1 -n ${cdu_video1_num} -c ${cdu_dump_num}
	else
		printf "${C_F_LINE}[ Check ] : video1 node connect ${cdu_video1_num} video${C_F_RES}\n"
	fi
	echo "${S_L_STR0// /-}"
}

check_cdu_slave_status(){
	# check cdu slave video status
	function_lever_first_slave "camera in-position status"
	# slave port cdu camera in-position status
	ssh slave "get_camera_status.sh"
	check_cdu_camera_status
	function_lever_first_slave "dump image data"
	function_lever_second_master "dump video0 image data"
	# check dump video0 data 
	if [ "${cdu_video0_num}" -gt 0 ]
	then
		printf "Check dump video0 data...\n"
		ssh slave "timeout 10 dump_video0.sh -n ${cdu_video0_num}"
		function_lever_second_master "dump video0 image data and check size"
		ssh slave "dump_video.sh -i 0 -n ${cdu_video0_num} -c 100 -s ${F_P_HOME}/video0.tgz"
		local video0_size=$(ssh slave "ls -lh ${F_P_HOME}/video0.tgz |awk '{print $5}'")
		echo -e "${S_L_STR0// /-}\nvideo0.tgz size : ${video0_size}"
		ssh slave "rm -rf ${F_P_HOME}/video0.tgz"
		function_lever_second_master "dump video0 image date ${cdu_dump_num} fps"
		ssh slave "dump_video.sh -i 0 -n ${cdu_video0_num} -c ${cdu_dump_num}"
	else
		printf "${C_F_LINE}[ Check ] : video0 node connect ${cdu_video0_num} video${C_F_RES}\n"
	fi
	# check dump video1 data
	function_lever_second_master "dump video1 image data"
	if [ "${cdu_video1_num}" -gt 0 ]
	then
		printf "Check dump video1 data...\n"
		ssh slave "timeout 10 dump_video1.sh -n ${cdu_video1_num}"
		function_lever_second_master "dump video1 image data and check size"
		ssh slave "dump_video.sh -i 1 -n ${cdu_video1_num} -c 100 -s ${F_P_HOME}/video1.tgz"
		local video1_size=$(ssh slave "ls -lh ${F_P_HOME}/video1.tgz |awk '{print $5}'")
		echo -e "${S_L_STR0// /-}\nvideo1.tgz size : ${video1_size}"
		ssh slave "rm -rf ${F_P_HOME}/video1.tgz"
		function_lever_second_master "dump video1 image date ${cdu_dump_num} fps"
		ssh slave "dump_video.sh -i 1 -n ${cdu_video1_num} -c ${cdu_dump_num}"
	else
		printf "${C_F_LINE}[ Check ] : video1 node connect ${cdu_video1_num} video${C_F_RES}\n"
	fi
	echo "${S_L_STR0// /-}"
}

check_cdu_master_uos(){
	# check cdu master uos system
	# video uos system verification : runtime 20s
	function_lever_first_master "uos_camera-main function"
	if [ -d "${uos_name}" ]
	then 
		cd ${uos_name}
		. set_env.sh
		./bin/uos_camera-main &
		sleep 20
		ps -ef |grep uos_camera-main |awk '{print $2}'|xargs sudo kill -9
		sleep 14
	else
		printf "${C_F_LINE}[ Check ] : ${SOURCE_PATH}/config.json set_uos_name error${C_F_RES}\n"
	fi
	echo "${S_L_STR0// /-}"
}

check_cdu_slave_uos(){
	# check cdu slave uos system
	# video uos system verifcation : runtime 20s
	function_lever_first_slave "uos_camera-main"
	if [ -d "${uos_name}" ]
	then 
		ssh -X slave "cd ${uos_name}
		. set_env.sh 
		./bin/uos_camera-main &
		sleep 20
		sudo killall uos_camera-main"
		sleep 14
	else
		printf "${C_F_LINE}[ Check ] : ${SOURCE_PATH}/config.json set_uos_name error${C_F_RES}\n"
	fi
	echo "${S_L_STR0// /-}"
}

check_cdu_dump_data(){
	# change camera dump data
	printf "\n${C_F_LINE}master port video node dump data${C_F_RES}\n"
	dump_video0.sh -n ${cdu_video0_num}
	sleep 2
	dump_video1.sh -n ${cdu_video1_num}
	sleep 2
	printf "\n${C_F_LINE}slave port video node dump data${C_F_RES}\n"
	ssh slave "dump_video0.sh -n ${cdu_video0_num}"
	sleep 2
	ssh slave "dump_video1.sh -n ${cdu_video1_num}"
	sleep 2
}

check_cdu_dump_rate(){
	# change camera dump data
	function_lever_first_master "change video dump rate"
	for i in $(seq 10 5 25)
	do
		function_lever_second_master "change video dump rate $i"
		config_ub964.sh -f $i
		sleep 10
		check_cdu_dump_data
	done
	echo "${S_L_STR0// /-}"
	function_lever_first_slave "change video dump rate"
	for i in $(seq 10 5 25)
	do
		function_lever_second_master "change video dump rate $i"
		ssh slave "config_ub964.sh -f $i"
		sleep 10
		check_cdu_dump_data
	done
	echo "${S_L_STR0// /-}"
}

check_cdu_camera_reg(){
	# check slave 964 & 913 
	function_lever_first_master "camera reg (964 && 913) error"
	function_lever_second_master "dump_camera_reg.sh help info"
	ssh slave "dump_camera_reg.sh -h"
	for ((i=0;i<=7;i++))
	do
		function_lever_second_master "dump camera reg video$i"
		ssh slave "dump_camera_reg.sh -d $i"
	done
	echo "${S_L_STR0// /-}"
}

check_cdu_isp_burn(){
	# burn isp file
	function_lever_first_master "burn camera isp"
	function_lever_second_master "burn_isp.sh help info"
	ssh slave "burn_isp.sh -h"
	echo "${S_L_STR0// /-}"
	for ((i=0;i<=7;i++))
	do
		function_lever_second_master "burn video$i isp file"
		ssh slave "burn_isp.sh -d $i -f xxxx"
	done
	echo "${S_L_STR0// /-}"
}

check_cdu_isp_read(){
	# read isp info
	function_lever_first_master "check read camera isp info"
	function_lever_second_master "camera_flash_op help info"
	ssh slave "camera_flash_op -h"
	echo "${S_L_STR0// /-}"
	for ((i=0;i<=7;i++))
	do
		function_lever_second_master "camera count (camera_flash_op -v GG3X -d $i -5 -r)"
		ssh slave "camera_flash_op -v GG3X -d $i -5 -r"
		function_lever_second_master "YY/MM/DD (camera_flash_op -v GG3X -d $i -6 -r)"
		ssh slave "camera_flash_op -v GG3X -d $i -6 -r"
		function_lever_second_master "SN (camera_flash_op -v GG3X -d $i -7 -r)"
		ssh slave "camera_flash_op -v GG3X -d $i -7 -r"
		function_lever_second_master "Hardware version (camera_flash_op -v GG3X -d $i -8 -r)"
		ssh slave "camera_flash_op -v GG3X -d $i -8 -r"
		function_lever_second_master "Calibration Data (camera_flash_op -v GG3X -d $i -9 -r)"
		ssh slave "camera_flash_op -v GG3X -d $i -9 -r"
	done
	echo "${S_L_STR0// /-}"
}

check_cdu_isp_write(){
	# write isp info
	function_lever_first_master "check write camera isp info"
	for ((i=0;i<=7;i++))
	do
		function_lever_second_master "camera count (camera_flash_op -v GG3X -d $i -5 -w 01)"
		ssh slave "camera_flash_op -v GG3X -d $i -5 -w 01"
		function_lever_second_master "YY/MM/DD (camera_flash_op -v GG3X -d $i -6 -w 20191120)"
		ssh slave "camera_flash_op -v GG3X -d $i -6 -w 20191120"
		function_lever_second_master "SN (camera_flash_op -v GG3X -d $i -7 -w WS1234566)"
		ssh slave "camera_flash_op -v GG3X -d $i -7 -w WS1234566"
		function_lever_second_master "Hardware version (camera_flash_op -v GG3X -d $i -8 -w e1000101)"
		ssh slave "camera_flash_op -v GG3X -d $i -8 -w e1000101"
		function_lever_second_master "Calibration Data (camera_flash_op -v GG3X -d $i -9 -w 1000101010010101101001)"
		ssh slave "camera_flash_op -v GG3X -d $i -9 -w 1000101010010101101001"
	done
	echo "${S_L_STR0// /-}"
}

check_cdu_config_para(){
	local switch_isp_burn=$(jq '.para_cdu.cdu_switch_isp_burn' ${SOURCE_PATH}/config.json)
	local switch_isp_write=$(jq '.para_cdu.cdu_switch_isp_write' ${SOURCE_PATH}/config.json)
	if [ "${switch_isp_burn}" -eq 1 ]
	then
		check_cdu_isp_burn
	else
		printf "${SOURCE_PATH}/config.json para_cdu.cdu_switch_isp_burn value is ${switch_isp_burn}\n"
		printf "\tcdu_switch_isp_burn: 0-disable ; 1-enable\n" 
	fi
	if [ "${switch_isp_write}" -eq 1 ]
	then
		check_cdu_isp_write
	else
		printf "${SOURCE_PATH}/config.json para_cdu.cdu_switch_isp_write value is ${switch_isp_write}\n"
		printf "\tcdu_switch_isp_write: 0-disable ; 1-enable\n" 
	fi
}

check_cdu(){
	# check cdu module
	local cdu_video0_num=$(jq '.para_cdu.cdu_video0_num' ${SOURCE_PATH}/config.json)
	local cdu_video1_num=$(jq '.para_cdu.cdu_video1_num' ${SOURCE_PATH}/config.json)
	local cdu_dump_num=$(jq -r ".para_cdu.cdu_dump_num" ${SOURCE_PATH}/config.json)
	local cdu_uos_name=$(jq -r ".set_uos_name" ${SOURCE_PATH}/config.json)
	local uos_name=${F_P_HOME}/${cdu_uos_name}/run
	check_cdu_master_dsi
	check_cdu_master_status
	check_cdu_slave_status
	check_cdu_master_uos
	check_cdu_slave_uos
	check_cdu_dump_rate
	check_cdu_config_para
	check_cdu_isp_read
	check_cdu_camera_reg
}
