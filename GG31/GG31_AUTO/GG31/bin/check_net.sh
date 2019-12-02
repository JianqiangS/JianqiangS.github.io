#!/bin/bash
SOURCE_PATH=/home/worker/GG31
source ${SOURCE_PATH}/etc/common.sh
source ${SOURCE_PATH}/etc/function.sh

check_net_ping_result(){
	# check net ping package and count accept & lost & lost rate
	ping -c "$1" "$2" |tee ${r_p_log}/diag_module.log
	local received=$(grep received ${r_p_log}/diag_module.log)
	local result=$(echo "${received}" |awk -F "," '{print $2}' |awk '{print $1}')
	local lost_rate=$(echo "${received}" |awk -F "," '{print $3}'|awk '{print $1}')
	let "lost=$1-$result"
	echo "${S_L_STR0// /-}"
	if [ "${result}" -eq "$1" ]
	then
		printf "ping -c $1 $2 : total $1 : accept ${result} : lost ${lost} : lost_rate ${lost_rate}%\n" 
	elif [ -z "${result}" ]
	then
		printf "ping -c $1 $2 : total $1 : accept 0 : lost $1 : lost_rate 100%%\n"
	elif [ "${result}" -ge 0 ] && [ "${result}" -lt "$1" ]
	then
		printf "ping -c $1 $2 : total $1 : accept ${result} : lost ${lost} : lost_rate ${lost_rate}%\n"
	fi
}

check_net_master_common(){
	# check master net ping ip && domain 
	function_lever_second_master "network configuration information"
	ifconfig
	function_lever_second_master "${R_P_HOME} wvdial.log information"
	cat ${R_P_HOME}/wvdial.log
	if [ "$?" -ne 0 ]
	then
		printf "${C_F_LINE}[ Check ] : wvdial.log is not exist${C_F_RES}\n"
	fi
	function_lever_second_master "networking service status"
	systemctl status networking.service |head -n 30
	function_lever_second_master "connect ${net_ping_ip} (${net_ping_num_v})"
	check_net_ping_result ${net_ping_num_v} ${net_ping_ip}
	function_lever_second_master "connect ${net_ping_ip} (${net_ping_num_s})"
	check_net_ping_result ${net_ping_num_s} ${net_ping_ip}
	function_lever_second_master "connect ${net_ping_domain} (${net_ping_num_v})"
	check_net_ping_result ${net_ping_num_v} ${net_ping_domain}
	function_lever_second_master "connect ${net_ping_domain} (${net_ping_num_s})"
	check_net_ping_result ${net_ping_num_s} ${net_ping_domain}
	function_lever_second_master "data upload"
	upload_logs.sh
	function_lever_second_master "data download"
	wget -O ${r_p_log}/net.log ${net_ping_domain}
}

check_net_master_internal(){
	# check master net internal 4g
	function_lever_first_master "network environment : internal 4G"
	function_lever_second_master "4G huawei module"
	sleep 1 && lsusb
	echo "${S_L_STR0// /-}"
	local net_huawei=$(lsusb |grep -i huawei |awk '{print $7}')
	if [ "${net_huawei}" == "Huawei" ]
	then 
		printf "${C_F_LINE}[ Check ] : 4G_HUAWEI Module exist ...${C_F_RES}\n"
		function_lever_second_master "/dev/ttyUSB node"
		sleep 1 && ls -l /dev/ttyUSB* 
		echo "${S_L_STR0// /-}"
		local net_usb=$(ls /dev/ttyUSB0)
		if [ "${net_usb}" == "/dev/ttyUSB0" ]
		then 
			printf "${C_F_LINE}[ Check ] : 4G_modle ttyUSB node is ${net_usb}${C_F_RES}\n"
			check_net_master_common
		else
			printf "${C_F_LINE}[ Check ] : 4G_modle ttyUSB node not exist${C_F_RES}\n"
		fi  
	else
		sleep 1 && printf "${C_F_LINE}[ Check ] : 4G_HUAWEI Module not exist${C_F_RES}\n"
	fi
	echo "${S_L_STR0// /-}"
}

check_net_master_external(){
	# check master net external route
	function_lever_first_master "network environment : external route"
	function_lever_second_master "external route ip"
	route -n
	check_net_master_common
	echo "${S_L_STR0// /-}"
}

check_net_master_wifi(){
	# check master net wifi
	function_lever_first_master "network environment : WIFI"
	function_lever_second_master "wifi account & password setting information"
	local wifi_set_user=$(jq -r ".para_net.net_wifi_set_user" ${SOURCE_PATH}/config.json)
	local wifi_set_pass=$(jq -r ".para_net.net_wifi_set_pass" ${SOURCE_PATH}/config.json)
	printf "set_wifi.sh ${wifi_set_user} ${wifi_set_pass}\n"
	set_wifi.sh ${wifi_set_user} ${wifi_set_pass}
	function_lever_second_master "wifi account & password information"
	grep -A5 -n wlan0 /etc/network/interfaces
	function_lever_second_master "lspci information"
	lspci
	function_lever_second_master "wlan driver module"
	lsmod
	function_lever_second_master "wifi signal strength mode 1"
	iwconfig wlan0
	function_lever_second_master "wifi signal strength mode 2"
	sudo wpa_cli -i wlan0 scan_result
	check_net_master_common
	echo "${S_L_STR0// /-}"
}

check_net_slave(){
	# check slave network
	function_lever_first_slave "network environment"
	function_lever_second_master "connect ${net_ping_ip} (${net_ping_num_v})"
	ssh slave "ifconfig eth0 && ping -c ${net_ping_num_v} ${net_ping_ip}"
	function_lever_second_master "connect ${net_ping_domain} (${net_ping_num_v})"
	ssh slave "ifconfig eth0 && ping -c ${net_ping_num_v} ${net_ping_domain}"
	echo "${S_L_STR0// /-}"
}

check_net_lidar(){
	# check connetc lidar net
	function_lever_first_master "lidar network"
	ping -c 1 ${net_ping_lidar} > /dev/null
	if [ "$?" -eq 0 ]
	then
		function_lever_second_master "master && lidar (${net_ping_lidar})"
		ping -c ${net_ping_num_s} ${net_ping_lidar}
		function_lever_first_slave "lidar network"
		function_lever_second_master "slave && lidar (${net_ping_lidar})"
		ssh slave "ifconfig eth0 && ping -c ${net_ping_num_s} ${net_ping_lidar}"
	else
		echo "${S_L_STR0// /-}"
		printf "${SOURCE_PATH}/config.json para_net.net_ping_lidar error or not exist\n"
	fi
	echo "${S_L_STR0// /-}"
}

check_net_bb(){
	# check connetc bb net
	function_lever_first_master "bb network"
	ping -c 1 ${P_I_BLACK} > /dev/null
	if [ "$?" -eq 0 ]
	then
		function_lever_second_master "master && bb (${P_I_BLACK})"
		ping -c ${net_ping_num_s} ${P_I_BLACK}
		function_lever_first_slave "bb network"
		function_lever_second_master "slave && bb (${P_I_BLACK})"
		ssh slave "ifconfig eth0 && ping -c ${net_ping_num_s} ${P_I_BLACK}"
	else
		echo "${S_L_STR0// /-}"
		printf "GG3.1 not connect Blackbox ...\n"
	fi
	echo "${S_L_STR0// /-}"
}
	
check_net(){ 
	# check network function
	local net_exte_a=$(route -n |grep 192.168.100.1 |awk '{print $2}')
	local net_exte_s="192.168.100.1"
	local net_inte_a=$(ifconfig |grep ppp0 |awk '{print $1}')
	local net_inte_s="ppp0"
	local net_wifi_a=$(ifconfig |grep wlan0 |awk '{print $1}')
	local net_wifi_s="wlan0"
	local net_ping_num_v=$(jq -r ".para_net.net_ping_num_verify" ${SOURCE_PATH}/config.json)
	local net_ping_num_s=$(jq -r ".para_net.net_ping_num_stress" ${SOURCE_PATH}/config.json)
	local net_ping_domain=$(jq -r ".para_net.net_ping_domain" ${SOURCE_PATH}/config.json)
	local net_ping_lidar=$(jq -r ".para_net.net_ping_lidar" ${SOURCE_PATH}/config.json)
	local net_ping_ip=$(jq -r ".para_net.net_ping_ip" ${SOURCE_PATH}/config.json)
	if [[ "${net_exte_a}" == "${net_exte_s}" ]] && [[ "${net_inte_a}" != "${net_inte_s}" ]]
	then
		check_net_master_external
		check_net_slave 
		check_net_lidar
		check_net_bb
	elif [ "${net_inte_a}" == "${net_inte_s}" ]
	then 
		check_net_master_internal
		check_net_slave
		check_net_lidar
		check_net_bb
	elif [ "${net_wifi_a}" == "${net_wifi_s}" ]
	then 
		check_net_master_wifi
		check_net_slave
		check_net_lidar
		check_net_bb
	else  
		printf "\n${C_F_LINE}[ Check ] : Network status error${C_F_RES}\n"
	fi
}
check_net
