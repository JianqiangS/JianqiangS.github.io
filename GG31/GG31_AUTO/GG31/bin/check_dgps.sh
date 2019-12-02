#!/bin/bash
SOURCE_PATH=/home/worker/GG31
source ${SOURCE_PATH}/etc/common.sh
source ${SOURCE_PATH}/etc/function.sh

check_dgps_config_baud(){
	# dgps config baudrate
	function_lever_second_master "dgps config baudrate"
	cd ${R_P_LIB_FILE}/dgps_cfg
	./dgps_cfg.sh
}

check_dgps_config_rtk(){
	# check master dgps configure
	function_lever_second_master "dgps set rpk port"
	local dgps_rtk_port=$(jq -r ".para_dgps.dgps_rtk_port" ${SOURCE_PATH}/config.json)
	printf "set_rtk_port.sh ${dgps_rtk_port}\n"
	set_rtk_port.sh ${dgps_rtk_port}
	grep -B1 ${dgps_rtk_port} /usr/local/bin/rtkproc.sh
}

check_dgps_config(){
	function_lever_first_master "dgps config"
	check_dgps_config_baud
	check_dgps_config_rtk
	echo "${S_L_STR0// /-}"
}

check_dgps_location_info(){
	# diagnoise dpgs module power status parameter
	printf "Check /dev/ttyTHS1 data ...\n"
	/usr/bin/expect << eof
		spawn sudo picocom -b 115200 /dev/ttyTHS1 
		sleep 6
		expect "$GPRMC"
		send "\01"
		send "\117"
		interact
eof
}

check_dgps_location_diag(){
	# diagnoise dgps serial data 
	check_dgps_location_info |tee ${r_p_log}/diag_module.log
	local result=$(grep GPGGA ${r_p_log}/diag_module.log)
	if [ -n "${result}" ]
	then
		local state="normal"	
	else
		local state="abnormal"	
	fi
	printf "\n${C_F_LINE}[ Check ] : dgps output data ${state}${C_F_RES}\n" 
}

check_dgps_location(){
	# check master dgps location infomation
	function_lever_second_master "dgps location information (picocom)"
	check_dgps_location_diag
}

check_dgps_location_nc(){
	# with nc method check dgps location
	function_lever_second_master "dgps location infomation (nc)"
	timeout 1 nc 192.168.100.99 2001
}

check_dgps_lostrate(){
	# check master dgps lost rate
	local dgps_frame_t=$(grep -a -c "G" ${r_p_log}/diag_module.log) 
	local dgps_frame_a=$(grep -a "G" ${r_p_log}/diag_module.log |grep -c "$")
	function_lever_second_master "dgps lost frames"
	if [ "${dgps_frame_t}" -ne 0 ]
	then
		if [ "${dgps_frame_t}" == "${dgps_frame_a}" ]
		then
			local state="continuous"
		else
			local state="losts"
		fi
	else
		local state="null"
	fi
	printf "Total frames : ${dgps_frame_t} | Actual frames : ${dgps_frame_a}\n"
	printf "${C_F_LINE}[ Check ] : dgps output frames ${state}${C_F_RES}\n" 
}

check_dgps_data(){
	function_lever_first_master "dgps location data"
	check_dgps_location
	check_dgps_lostrate
	check_dgps_location_nc
	echo "${S_L_STR0// /-}"
}

check_dgps(){
	check_dgps_config
	check_dgps_data
}
