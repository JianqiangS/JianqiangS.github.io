#!/bin/bash
SOURCE_PATH=/home/worker/GG31
source ${SOURCE_PATH}/etc/common.sh
source ${SOURCE_PATH}/etc/function.sh

check_ioin_master_para(){
	# check master io_internal parameter
	function_lever_second_master "ssd properties mode 1"
	printf "cat /sys/block/${ioin_ssd_type_m}/queue/rotational :"
	printf "$(cat /sys/block/${ioin_ssd_type_m}/queue/rotational)\n"
	function_lever_second_master "ssd properties mode 2"
	sleep 1 && lsblk -d -o name,size,rota
	function_lever_second_master "ssd exists status mode 1"
	sleep 1 && sudo fdisk -l |grep /dev/${ioin_ssd_type_m}
	function_lever_second_master "ssd exists status mode 2"
	sleep 1 && df -ahl
	echo "${S_L_STR0// /-}"
}

check_ioin_master_write(){
	# check master io_internal write method
	function_lever_second_master "list file in ${ioin_ssd_monuted_m}"
	ls -l ${ioin_ssd_monuted_m}
	function_lever_second_master "copy file to ${ioin_ssd_monuted_m}"
	cp /etc/uisee_release ${ioin_ssd_monuted_m}
	ls -l ${ioin_ssd_monuted_m}
	local li=(" " "; sync" "conv=fdatasync" "oflag=dsync")
	for ((i=0;i<=3;i++))
	do
		function_lever_second_master "write file from ${C_D_ZERO} to ${ioin_ssd_monuted_m} mode $i"
		printf "\n${C_F_GREEN}dd if=${C_D_ZERO} of=${ioin_ssd_monuted_m}/uisee.log bs=${ioin_dd_bs} count=${ioin_dd_count} ${li[$i]}${C_F_RES}\n"
		time dd if=${C_D_ZERO} of=${ioin_ssd_monuted_m}/uisee.log bs=${ioin_dd_bs} count=${ioin_dd_count} ${li[$i]}
		sleep 2
	done
}

check_ioin_master_read(){
	# check master io_internal read function
	local li=(" " "; sync" "conv=fdatasync" "oflag=dsync")
	for ((i=0;i<=3;i++))
	do
		function_lever_second_master "read file from ${ioin_ssd_monuted_m} to ${C_D_NULL} mode $i"
		printf "\n${C_F_GREEN}dd if=${ioin_ssd_monuted_m}/uisee.log of=${C_D_NULL} bs=${ioin_dd_bs} count=${ioin_dd_count} ${li[$i]}${C_F_RES}\n"
		time dd if=${ioin_ssd_monuted_m}/uisee.log of=${C_D_NULL} bs=${ioin_dd_bs} count=${ioin_dd_count} ${li[$i]}
		sleep 2
	done
	echo "${S_L_STR0// /-}"
}

check_ioin_slave_para(){
	# check slave io_internal parameter
	function_lever_second_master "ssd properties mode 1"
	printf "cat /sys/block/${ioin_ssd_type_s}/queue/rotational : "
	printf "$(ssh slave "cat /sys/block/${ioin_ssd_type_s}/queue/rotational")"
	function_lever_second_master "ssd properties mode 2"
	ssh slave "sleep 1 && lsblk -d -o name,size,rota"
	function_lever_second_master "ssd exists status mode 1"
	ssh slave "sleep 1 && sudo fdisk -l |grep /dev/${ioin_ssd_type_s}"
	function_lever_second_master "ssd exists status mode 2"
	ssh slave "sleep 1 && df -ahl"
	echo "${S_L_STR0// /-}"
}

check_ioin_slave_write(){
	# check slave io_internal write function
	function_lever_second_master "list file in ${ioin_ssd_monuted_s}"
	ssh slave "ls -l ${ioin_ssd_monuted_s}"
	function_lever_second_master "copy file to ${ioin_ssd_monuted_s}"
	ssh slave "cp /etc/uisee_release ${ioin_ssd_monuted_s}"
	ssh slave "ls -l ${ioin_ssd_monuted_s}"
	local li=(" " "; sync" "conv=fdatasync" "oflag=dsync")
	for ((i=0;i<=3;i++))
	do
		function_lever_second_master "write file from ${C_D_ZERO} to ${ioin_ssd_monuted_s} mode $i"
		printf "\n${C_F_GREEN}dd if=${C_D_ZERO} of=${ioin_ssd_monuted_s}/uisee.log bs=${ioin_dd_bs} count=${ioin_dd_count} ${li[$i]}${C_F_RES}\n"
		ssh slave "time dd if=${C_D_ZERO} of=${ioin_ssd_monuted_s}/uisee.log bs=${ioin_dd_bs} count=${ioin_dd_count} ${li[$i]}"
		sleep 2
	done
	echo "${S_L_STR0// /-}"
}

check_ioin_slave_read(){
	# check slave io_internal read function
	local li=(" " "; sync" "conv=fdatasync" "oflag=dsync")
	for ((i=0;i<=3;i++))
	do
		function_lever_second_master "read file from ${ioin_ssd_monuted_s} to ${C_D_NULL} mode $i"
		printf "\n${C_F_GREEN}dd if=${ioin_ssd_monuted_s}/uisee.log of=${C_D_NULL} bs=${ioin_dd_bs} count=${ioin_dd_count} ${li[$i]}${C_F_RES}\n"
		ssh slave "time dd if=${ioin_ssd_monuted_s}/uisee.log of=${C_D_NULL} bs=${ioin_dd_bs} count=${ioin_dd_count} ${li[$i]}"
		sleep 2
	done
	echo "${S_L_STR0// /-}"
}

check_ioin_master(){
	# check ioin module in master port
	local ioin_ssd_type_m=$(jq -r ".para_ioin.ioin_insert_master.ioin_ssd_type" ${SOURCE_PATH}/config.json)
	local ioin_ssd_monuted_m=$(jq -r ".para_ioin.ioin_insert_master.ssd_ioin_monuted" ${SOURCE_PATH}/config.json)
	if [ -b "${ioin_ssd_type_m}" ]
	then
		if [ -d "${ioin_ssd_monuted_m}" ]
		then
			function_lever_first_master "ioin ssd (${ioin_ssd_type_m})"
			check_ioin_master_para
			check_ioin_master_read
			check_ioin_master_write
		else
			printf "${SOURCE_PATH}/config.json para_ioin...ioin_ssd_monuted error\n"			
		fi
	else
		printf "${SOURCE_PATH}/config.json para_ioin...ioin_ssd_type error\n"
	fi
}

check_ioin_slave(){
	# check ioin module in slave port
	local ioin_ssd_type_s=$(jq -r ".para_ioin.ioin_insert_slave.ioin_ssd_type" ${SOURCE_PATH}/config.json)
	local ioin_ssd_monuted_s=$(jq -r ".para_ioin.ioin_insert_slave.ssd_ioin_monuted" ${SOURCE_PATH}/config.json)
	local ioin_sda_t=$(ssh slave "df -h |grep ${ioin_ssd_type_s}")
	local ioin_sda_m=$(ssh slave "df -h |grep ${ioin_ssd_monuted_s}")
	if [ -n "${ioin_sda_s}" ]
	then
		if [ -n "${ioin_sda_m}" ]
		then
			function_lever_first_slave "ioin ssd (${ioin_ssd_type_s})"
			check_ioin_slave_para
			check_ioin_slave_read
			check_ioin_slave_write
		else
			printf "${SOURCE_PATH}/config.json para_ioin...ioin_ssd_monuted error\n"			
		fi
	else
		printf "${SOURCE_PATH}/config.json para_ioin...ioin_ssd_type error\n"
	fi
}

check_ioin(){
	local ioin_dd_bs=$(jq -r ".para_ioin.ioin_dd_bs" ${SOURCE_PATH}/config.json)
	local ioin_dd_count=$(jq -r ".para_ioin.ioin_dd_count" ${SOURCE_PATH}/config.json)
	check_ioin_master
	check_ioin_slave
}
