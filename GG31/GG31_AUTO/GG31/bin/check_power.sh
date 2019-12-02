#!/bin/bash
SOURCE_PATH=/home/worker/GG31
source ${SOURCE_PATH}/etc/common.sh
source ${SOURCE_PATH}/etc/function.sh

check_module_power_status(){
	# module status diag & enable & disable
	local li=("diag" "disable" "diag" "enable" "diag")
	local li_len=$(printf "${#li[@]}\n")
	for ((i=0;i<${li_len};i++))
	do
		function_lever_first_master "${li[$i]} all module power status"
		echo "${S_L_STR0// /-}"
		module_power_ctrl.sh ${li[$i]} && sleep 2
		echo "${S_L_STR0// /-}"
	done
}

diag_module(){
	echo "${S_L_STR2// /*}" && sleep 2
	module_power_ctrl.sh diag
	echo "${S_L_STR2// /*}" && sleep 2
}

diag_ping_result(){
	# statistics module power ping result
	local result=$(grep received ${r_p_log}/diag_module.log |awk -F "," '{print $2}' |awk '{print $1}')
	if [ "${result}" -eq 0 ]
	then
		printf "${C_F_LINE}[ Check ] : Lost all package${C_F_RES}\n" 
	elif [ "${result}" -eq "${power_ping_num}" ]
	then
		printf "${C_F_LINE}[ Check ] : Accept all package${C_F_RES}\n"
	elif [ "${result}" -gt 0 ] && [ "${result}" -lt "${power_ping_num}" ]
	then
		printf "${C_F_LINE}[ Check ] : Lost some package${C_F_RES}\n" 
	fi
}

diag_result_status(){
	# excute result status check
	if [ -n "$1" ]
	then
		printf "${C_F_LINE}[ Check ] : $2 ${C_F_RES}\n"
	else
		printf "${C_F_LINE}[ Check ] : $3 ${C_F_RES}\n"
	fi
}

diag_module_4g(){
	# diagnoise 4G module parameter
	local net_usb0=/dev/ttyUSB0
	local net_huawei=Huawei
	printf "Check /dev/ttyUSB0 node ...\n"
	ls /dev/ttyUSB* |tee ${r_p_log}/diag_module.log
	local result_0=$(grep ${net_usb0} ${r_p_log}/diag_module.log)
	diag_result_status "${result_0}" "${net_usb0} exist" "${net_usb0} not exist"

	printf "Check 4G Huawei module ...\n"
	lsusb | tee ${r_p_log}/diag_module.log
	local result_1=$(grep ${net_huawei} ${r_p_log}/diag_module.log)
	diag_result_status "${result_1}" "${net_huawei} exist" "${net_huawei} not exist"
}

diag_module_wifi(){
	# diagnoist WIFI module power status parameter
	local net_wire=Wire
	local net_wlan=wlan
	printf "Check wifi pci device ...\n"
	lspci |tee ${r_p_log}/diag_module.log
	local result_0=$(grep ${net_wire} ${r_p_log}/diag_module.log)
	diag_result_status "${result_0}" "${net_wire} pci exist" "${net_wire} pci not exist"

	printf "check wifi drive module ...\n"
	lsmod |tee ${r_p_log}/diag_module.log
	local result_1=$(grep ${net_wlan} ${r_p_log}/diag_module.log)
	diag_result_status "${result_1}" "${net_wlan} driver exist" "${net_wlan} driver not exist"
}

diag_module_lidar(){
	# diagnoise lidar module and lidar switch module status parameter
	printf "ping ${P_I_LIDAR}\n"
	ping -c ${power_ping_num} ${P_I_LIDAR} |tee ${r_p_log}/diag_module.log
	diag_ping_result
}

check_module_lidar_single(){
	# check single lidar power enable or disable , and check lidar function
	function_lever_first_master "single lidar module power status"
	for i in {0..3..1}
	do
		function_lever_second_master "single lidar port $i module power status"
		printf "Lidar $i port power disable ...\n"
		lidar_disable.sh $i
		diag_module && sleep 2
		printf "\nLidar $i port power enable ...\n"
		lidar_enable.sh $i
		diag_module && sleep 2
	done
	echo "${S_L_STR0// /-}"
}

diag_module_1g_switch(){
	# diagnoise 1g switch module status
	printf "ping ${P_I_SLAVE} ...\n"
	ping -c ${power_ping_num} ${P_I_SLAVE} |tee ${r_p_log}/diag_module.log
	diag_ping_result
}

diag_module_dgps_tty(){
	# diagnoise dpgs module power status parameter
	printf "Check /dev/ttyTHS1 data ...\n"
	which expect > ${C_D_NULL}
	if [ $? -eq 0 ]
	then
		/usr/bin/expect << eof
			spawn sudo picocom -b 115200 /dev/ttyTHS1 
			expect "$GPRMC"
			sleep 1
			send "\01"
			send "\117"
			interact
eof
	fi
}

diag_module_dgps(){
	# diagnoise dgps serial data 
	diag_module_dgps_tty |tee ${r_p_log}/diag_module.log
	local result=$(grep GPGGA ${r_p_log}/diag_module.log)
	diag_result_status "${result}" "dgps data normal output" "dgps data abnormal output"
}

check_dgps_location(){
	# check master dgps location infomation
	function_lever_first_master "dgps location information"
	echo "${S_L_STR0// /-}"
	diag_module_dgps
	echo "${S_L_STR0// /-}"
}

check_dgps_lostrate(){
	# check master dgps lost rate
	function_lever_first_master "dgps output frames num"
	echo "${S_L_STR0// /-}"
	local dgps_f_t=$(grep -a -c "G" ${r_p_log}/diag_module.log) 
	local dgps_f_a=$(grep -a "G" ${r_p_log}/diag_module.log |grep -c "$")
	printf "Total frames : ${dgps_f_t} | Actual frames : ${dgps_f_a}\n"
	if [ "${dgps_f_t}" == "${dgps_f_a}" ]
	then
		printf "${C_F_LINE}[ Check ] : dgps frame data continu${C_F_RES}\n"
	else
		printf "${C_F_LINE}[ Check ] : dgps frame date lost${C_F_RES}\n"
	fi
	echo "${S_L_STR0// /-}"
}

diag_module_camera(){
	# diagnoise camera module power status parameter
	printf "Check camera module power status ...\n"
	timeout 2 config_ub964.sh 
	if [ $? -eq 0 ]
	then
		printf "${C_F_LINE}[ Check ] : camera module power status is success${C_F_RES}\n"
	else
		printf "${C_F_LINE}[ Check ] : camera module power status is failed${C_F_RES}\n"
	fi
}

diag_module_camera_single(){
	# single camera power disable or enable , check single camera function
	# view camera in-position information
	if [ -s ${r_p_log}/camera_status.log ]
	then
		# get the number of camera connections
		local video_info=$(grep $1 ${r_p_log}/camera_status.log)
		local video_num=$(echo "${video_info}" |wc -l)
		function_lever_first_master "single camera $1(in-position) module power status"
		if [ "${video_num}" -gt 0 ]
		then
			# init check video0 node connect number of video and dump function
			printf "Current $1 node online number : ${video_num}\n"
			sleep 5
			dump_video.sh -i $2 -n ${video_num} -c 100
			declare -i video_odd video_port
			for ((i=1;i<="${video_num}";i++))
			do
				echo "${S_L_STR0// /-}"
				# get the video node connect video port 0,1,2,3
				video_port=$(echo "${video_info}"|sort -k 3|awk '{print $3}'|sed -n ${i}p)
				function_lever_second_master "$1(in-position) port ${video_port} power status"
				# check $1 video0 or video1 node
				if [ "$1" == "video1" ]
				then
					let video_port=${video_port}+4
				fi
				printf "$1 node $video_port port camera power disable\n"
				camera_disable.sh ${video_port}
				sleep 3 && echo "${S_L_STR0// /-}"
				config_ub964.sh
				sleep 3 && echo "${S_L_STR0// /-}"
				list_version.sh |grep -A 5 $1 
				sleep 3	&& echo "${S_L_STR0// /-}"
				let video_odd=${video_num}-${i}
				if [ "${video_odd}" -eq 0 ]
				then
					break
				else
					dump_video.sh -i $2 -n ${video_odd} -c 100
				fi
			done
		fi
	fi
}

check_module_camera_single(){
	# check single camera status
	# get camera in-position information
	module_power_ctrl.sh camera enable > ${C_D_NULL}
	sleep 3
	config_ub964.sh > ${r_p_log}/camera_status.log
	# excute single video : camera_frame video0 0
	diag_module_camera_single video0 0
	echo -e "\n${S_L_STR1// /=}\n"
	# excute single video : camera_frame video0 1
	diag_module_camera_single video1 1
}

check_per_module(){
	# check per module power disable -->> diag -->> enable -->> diag
	function_lever_first_master "$1 module power status"
	echo "${S_L_STR0// /-}"
	module_power_ctrl.sh $1 disable
	diag_module
	$2
	echo -e "${S_L_STR2// /*}\n" && sleep 2
	module_power_ctrl.sh $1 enable
	diag_module
	$2
	echo "${S_L_STR0// /-}"
}

check_power(){
	# check all module power status
	local power_ping_num=$(jq ".para_power.power_ping_num" ${SOURCE_PATH}/config.json)
	#check_module_power_status
#	check_per_module "4g" "diag_module_4g"
#	check_per_module "wifi" "diag_module_wifi"
#	check_per_module "dgps" "diag_module_dgps"
#	check_per_module "lidar" "diag_module_lidar"
#	check_per_module "camera" "diag_module_camera"
#	check_per_module "1g_switch" "diag_module_1g_switch"
#	check_per_module "lidar_switch" "diag_module_lidar"
	#check_per_module "gmsl"
	check_module_camera_single
	check_module_lidar_single
}
