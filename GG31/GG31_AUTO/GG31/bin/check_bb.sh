#!/bin/bash
SOURCE_PATH=/home/worker/GG31
source ${SOURCE_PATH}/etc/common.sh
source ${SOURCE_PATH}/etc/function.sh

check_bb_access(){
	# check access bb 
	function_lever_first_master "access blackbox"
	echo "${S_L_STR0// /-}"
	/usr/bin/expect << eeooff
		spawn ssh root@192.168.100.77
		sleep 1
		expect "password" 
		send "0\r"
		expect "root" 
		spawn echo "Welcome login blackbox"
		interact
eeooff
	echo "${S_L_STR0// /-}"
}

check_bb_ping_port(){
	# check bb with other port interconnect, contain master/slave/lidar/bb/network(ip/domain)
	local bb_ping_num=$(jq -r ".para_bb.bb_ping_num" ${SOURCE_PATH}/config.json)
	ssh ${P_N_BB}@${P_I_BLACK} "ping -c ${bb_ping_num} $1"
}

check_bb_server_iperf(){
	ssh ${P_N_BB}@${P_I_BLACK} "iperf -u -s"
}

check_bb_interconnect(){
	#local li=(${P_I_MASTER} ${P_I_SLAVE} ${P_I_BLACK} "192.168.100.201" "192.168.100.202" "192.168.100.203")
	local li=(${P_I_MASTER} ${P_I_SLAVE} ${P_I_BLACK} "192.168.100.201")
	local li_len=$(printf "${#li[@]}\n")
	function_lever_first_master "bb interconnect"
	for ((i=0;i<${li_len};i++))
	do
		function_lever_second_master "bb and ${li[$i]} interconnect"
		check_bb_ping_port ${li[$i]}
	done

	local bb_iperf_band=$(jq -r ".para_bb.bb_iperf_band" ${SOURCE_PATH}/config.json)
	local bb_iperf_interval=$(jq -r ".para_bb.bb_iperf_interval" ${SOURCE_PATH}/config.json)
	local bb_iperf_time=$(jq -r ".para_bb.bb_iperf_time" ${SOURCE_PATH}/config.json)
	function_lever_second_master "bb and master iperf"
	check_bb_server_iperf &
	sleep 2
	iperf -u -c${P_I_BLACK} -t${bb_iperf_time} -i${bb_iperf_interval} -b${bb_iperf_band}M
	function_lever_second_master "bb and slave iperf"
	ssh slave "iperf -u -c${P_I_BLACK} -t${bb_iperf_time} -i${bb_iperf_interval} -b${bb_iperf_band}M"
	echo "${S_L_STR0// /-}"
}

check_bb_network(){
	local bb_ping_ip=$(jq -r ".para_bb.bb_ping_ip" ${SOURCE_PATH}/config.json)
	local bb_ping_domain=$(jq -r ".para_bb.bb_ping_domain" ${SOURCE_PATH}/config.json)
	local li1=("${bb_ping_ip}" "${bb_ping_domain}")
	local li1_len=$(printf "${#li1[@]}\n")
	function_lever_first_master "bb network interconnect"
	for ((i=0;i<${li1_len};i++))
	do
		function_lever_second_master "bb and ${li1[$i]} interconnect"
		check_bb_ping_port ${li1[$i]}
	done
	echo "${S_L_STR0// /-}"
}

check_bb_time(){
	# check bb time status
	local bb_date_change=$(jq -r ".para_bb.bb_date_change" ${SOURCE_PATH}/config.json)
	function_lever_first_master "bb time"
	function_lever_second_master "master & slave & bb port current time"
	function_time_sync
	function_lever_second_master "change bb port time"
	ssh ${P_N_BB}@${P_I_BLACK} << eof
		printf "change bb port time ${bb_date_change}\n"
		date -s "${bb_date_change}"
		printf "write change time into hardware\n"
		hwclock -w
eof
	function_progress_bar 1
	function_time_sync
	echo "${S_L_STR0// /-}"
}

check_bb_status(){
	function_lever_first_master "bb configuration"
	function_lever_second_master "bb software version"
	ssh ${P_N_BB}@${P_I_BLACK} "list_version"
	function_lever_second_master "bb ip"
	ssh ${P_N_BB}@${P_I_BLACK} "ifconfig"
	function_lever_second_master "cpu info"
	ssh ${P_N_BB}@${P_I_BLACK} "lscpu"
	function_lever_second_master "bb disk info"
	ssh ${P_N_BB}@${P_I_BLACK} "fdisk -l |grep -A 3 ${bb_ssd_type}"
	function_lever_second_master "bb mount path mode 1"
	ssh ${P_N_BB}@${P_I_BLACK} "df -hl |grep blackbox"
	function_lever_second_master "bb mount path mode 2"
	ssh ${P_N_BB}@${P_I_BLACK} "lsblk |grep blackbox"
	echo "${S_L_STR0// /-}"
}

check_bb_active_status(){
	local li=("can" "gps" "lidar*" "camera*")
	local li_len=$(printf "${#li[@]}\n")
	function_lever_first_master "bb active status"
	for ((i=0;i<${li_len};i++))
	do
		function_lever_second_master "bb port ${li[$i]} service status"
		ssh ${P_N_BB}@${P_I_BLACK} "systemctl status blackbox_u${li[$i]}.service"
		sleep 2
	done
	echo "${S_L_STR0// /-}"
}

check_bb_data_size_display(){
	printf "before 5 second $1 data size is\n"
	ssh ${P_N_BB}@${P_I_BLACK} "tree -Cs -ug ${F_P_BB}/$1$2"
	sleep 5
	printf "\nafter 5 second $1 data size is\n"
	ssh ${P_N_BB}@${P_I_BLACK} "tree -Cs -ug ${F_P_BB}/$1$2"
}

check_bb_data_size_change(){
	function_lever_second_master "bb storage $1 data size"
	check_bb_data_size_display $1
}

check_bb_data_size_lidar(){
	printf "before 5 second lidar data size is\n"
	ssh ${P_N_BB}@${P_I_BLACK} "ls -lh ${F_P_BB} |grep lidar$1"
	sleep 5
	printf "\nafter 5 second lidar data size is\n"
	ssh ${P_N_BB}@${P_I_BLACK} "ls -lh ${F_P_BB} |grep lidar$1"
}

check_bb_camdata_correctness(){
	echo "${S_L_STR0// /-}"
	for file in ${r_p_log}/camdata/*
	do
		printf "\ndisplay $file camdata\n"
		if [ -f $file/camera.h264 ]
		then
			timeout 20 ffplay ${file}/camera.h264
		else
			continue
		fi
		echo -e "\n${S_L_STR0// /-}"
	done
}

check_bb_data_size(){
	function_lever_first_master "bb storage data"
	check_bb_data_size_change can
	function_lever_second_master "can data correctness"
	ssh ${P_N_BB}@${P_I_BLACK} "tail -25 ${F_P_BB}/can/can.log"

	check_bb_data_size_change gps
	function_lever_second_master "gps data correctness"
	ssh ${P_N_BB}@${P_I_BLACK} "tail -25 ${F_P_BB}/gps/gps.log"

	function_lever_second_master "bb storage lidar data size"
	check_bb_data_size_lidar

	check_bb_data_size_change camdata
	function_lever_second_master "camera data correctness"
	ssh ${P_N_BB}@${P_I_BLACK} "scp -r ${F_P_BB}/camdata worker@${P_I_MASTER}:${r_p_log}"
	if [ "$?" -eq 0 ]
	then
		ls -l ${r_p_log}/camdata
		check_bb_camdata_correctness
	else
		printf "camdata file not exist ...\n"
	fi
	echo "${S_L_STR0// /-}"
}

check_bb_can_service_change(){
	function_lever_first_master "bb can service stop and start"
	echo "${S_L_STR0// /-}"
	printf "${C_F_LINE}bb port : systemctl stop blackbox_ucan.service${C_F_RES}\n"
	ssh ${P_N_BB}@${P_I_BLACK} "systemctl stop blackbox_ucan.service"
	check_bb_data_size_display can
	sleep 2
	printf "\n${C_F_LINE}bb port : systemctl start blackbox_ucan.service${C_F_RES}\n"
	ssh ${P_N_BB}@${P_I_BLACK} "systemctl start blackbox_ucan.service"
	check_bb_data_size_display can
	echo "${S_L_STR0// /-}"
}

check_bb_gps_service_change(){
	function_lever_first_master "bb gps service stop and start"
	echo "${S_L_STR0// /-}"
	printf "${C_F_LINE}bb port : systemctl stop blackbox_ugps.service${C_F_RES}\n"
	ssh ${P_N_BB}@${P_I_BLACK} "systemctl stop blackbox_ugps.service"
	check_bb_data_size_display gps
	sleep 2
	printf "\n${C_F_LINE}bb port : systemctl start blackbox_ugps.service${C_F_RES}\n"
	ssh ${P_N_BB}@${P_I_BLACK} "systemctl start blackbox_ugps.service"
	check_bb_data_size_display gps
	echo "${S_L_STR0// /-}"
}

check_bb_lidar_service_change(){
	function_lever_first_master "bb single lidar service stop and start"
	for ((i=1;i<=4;i++))
	do	
		function_lever_second_master "bb single lidar$i port service stop and start"
		printf "${C_F_LINE}bb port : systemctl stop blackbox_ulidar20$i.service${C_F_RES}\n"
		ssh ${P_N_BB}@${P_I_BLACK} "systemctl stop blackbox_ulidar20$i.service"
		check_bb_data_size_lidar "_20$i"
		sleep 2
		printf "\n${C_F_LINE}bb port : systemctl start blackbox_ulidar20$i.service${C_F_RES}\n"
		ssh ${P_N_BB}@${P_I_BLACK} "systemctl start blackbox_ulidar20$i.service"
		check_bb_data_size_lidar "_20$i"
	done
	echo "${S_L_STR0// /-}"
}

check_bb_camdata_service_change(){
	function_lever_first_master "bb single camdata service stop and start"
	for ((i=1;i<=8;i++))
	do	
		function_lever_second_master "bb single camera$i port service stop and start"
		printf "${C_F_LINE}bb port : systemctl stop blackbox_ucamera$i.service${C_F_RES}\n"
		ssh ${P_N_BB}@${P_I_BLACK} "systemctl stop blackbox_ucamera$i.service"
		check_bb_data_size_display "camdata" "/990$i"
		sleep 2
		printf "\n${C_F_LINE}bb port : systemctl start blackbox_ucamera$i.service${C_F_RES}\n"
		ssh ${P_N_BB}@${P_I_BLACK} "systemctl start blackbox_ucamera$i.service"
		check_bb_data_size_display "camdata" "/990$i"
	done
	echo "${S_L_STR0// /-}"
}

check_bb_service_change(){
	check_bb_can_service_change
	check_bb_gps_service_change
	check_bb_lidar_service_change
	check_bb_camdata_service_change
}

check_bb_can_bitrate(){
	function_lever_first_master "bb can bitrate"
	function_lever_second_master "bb bitrate configuration"
	ssh ${P_N_BB}@${P_I_BLACK} "grep --color -C3 bitrate /opt/blackbox/conf/config.json"
	for ((i=0;i<=1;i++))
	do
		function_lever_second_master "bb can$i bitrate"
		ssh ${P_N_BB}@${P_I_BLACK} "ip -details link show can$i"
		sleep 1
	done
	echo "${S_L_STR0// /-}"
}

check_bb_rollback_mode(){
	printf "$1 blackbox memory size\n"
	ssh ${P_N_BB}@${P_I_BLACK} "df -h|grep blackbox"
	printf "$1 blackbox e100.car6 file count\n"
	ssh ${P_N_BB}@${P_I_BLACK} "ls ${F_P_BB}/e100.car6/* |wc"
}

check_bb_rollback(){
	function_lever_first_master "bb data roolback"
	echo -e "\n${S_L_STR0// /-}"
	check_bb_rollback_mode "init"
	function_progress_bar 9
	ssh ${P_N_BB}@${P_I_BLACK} "fallocate -l 420G ${F_P_BB}/e100.car6/aa.log"
	check_bb_rollback_mode "full"
	echo "${S_L_STR0// /-}"
}

check_bb_write(){
	local li=(" " "; sync" "conv=fdatasync" "oflag=dsync")
	local li_len=$(printf "${#li[@]}\n")
	function_lever_first_master "bb write function"
	for ((i=0;i<${li_len};i++))
	do
		function_lever_second_master "dd if=${C_D_ZERO} of=${F_P_BB}/aa.log bs=${bb_dd_bs} count=${bb_dd_count} ${li[$i]}"
		ssh ${P_N_BB}@${P_I_BLACK} "dd if=${C_D_ZERO} of=${F_P_BB}/aa.log bs=${bb_dd_bs} count=${bb_dd_count} ${li[$i]}"
		sleep 2
	done
	echo "${S_L_STR0// /-}"
}

check_bb_read(){
	local li=(" " "; sync" "conv=fdatasync" "oflag=dsync")
	local li_len=$(printf "${#li[@]}\n")
	function_lever_first_master "bb read function"
	for ((i=0;i<${li_len};i++))
	do
		function_lever_second_master "dd if=${F_P_BB}/aa.log of=${C_D_NULL} bs=${bb_dd_bs} count=${bb_dd_count} ${li[$i]}"
		ssh ${P_N_BB}@${P_I_BLACK} "dd if=${F_P_BB}/aa.log of=${C_D_NULL} bs=${bb_dd_bs} count=${bb_dd_count} ${li[$i]}"
		sleep 2
	done
	echo "${S_L_STR0// /-}"
}

check_bb(){
	# check bb parameter and function
	ssh ${P_N_BB}@${P_I_BLACK} "ifconfig" > ${C_D_NULL}
	if [ "$?" -eq 0 ]
	then
		local bb_dd_bs=$(jq -r ".para_bb.bb_dd_bs" ${SOURCE_PATH}/config.json)
		local bb_dd_count=$(jq -r ".para_bb.bb_dd_count" ${SOURCE_PATH}/config.json)
		local bb_ssd_type=$(jq -r ".para_bb.bb_ssd_type" ${SOURCE_PATH}/config.json)
		ssh ${P_N_BB}@${P_I_BLACK} "lsblk |grep $bb_ssd_type" > ${C_D_NULL}
		if [ "$?" -eq 0 ]
		then
			check_bb_access
			check_bb_interconnect
			#check_bb_network
			check_bb_time
			check_bb_status
			check_bb_active_status
			check_bb_data_size
			check_bb_service_change
			check_bb_can_bitrate
			#check_bb_rollback
			check_bb_write
			check_bb_read
		else
			printf "${C_F_LINE}[ Check ] : ${SOURCE_PATH}/config.json bb_ssd_type error${C_F_RES}\n"
		fi
	else
		printf "${C_F_LINE}Blackbox not connect${C_F_RES}\n"
	fi
}
