#!/bin/bash
SOURCE_PATH=/home/worker/GG31_SYSTEM
source ${SOURCE_PATH}/etc/common.sh
source ${SOURCE_PATH}/etc/function.sh
source ${SOURCE_PATH}/etc/install_deb.sh

CAN_SHOW_IMAGE=$(jq -r ".para_can.can_image.show_interval" ${SOURCE_PATH}/config.json)
CAN_SWITCH_IMAGE=$(jq -r ".para_can.can_image.show_switch" ${SOURCE_PATH}/config.json)

can_dependency_package(){
	# Dependency package installation
	install_deb_check "csvlook" install_deb_csvkit
	install_deb_check "cutecom" install_deb_cutecom
	install_deb_check "expect" install_deb_expect
	install_deb_check "firefox" install_deb_firefox
	install_deb_check "gnuplot" install_deb_gnuplot
}

can_help_info_mode(){
	# Can test mode help information
	printf "Can_mode [1/2]\n"
	printf "\t1 : mean can test with GUI\n"
	printf "\t2 : mean can test with terminal\n"
}

can_ring_stress_excute_0(){
	# expect send test_can_unlimited
	while true
	do
		/usr/bin/expect << eof
			spawn sudo picocom -b 115200 /dev/ttyTHS2
			expect "Type"
			send "A10\r"
			sleep 2
			expect "Press ENTER to execute the previous command again" 
			send "test_can_unlimited\r"
			expect "Command not recognised"
			send "test_can_unlimited\r"
eof
		sleep 5
	done
}

can_ring_stress_excute(){
	can_ring_stress_excute_0 |tee -a ${R_P_LOG_CAN}/can_stress.log
}

can_ring_stress_statistic(){
	# can_ring result statistic error
	local i success=0 fail=0 total=0
	for i in $(echo "$error_status")
	do
		if [ "$i" -lt 1 ]
		then
			let success++
		elif [ "$i" -ge 1 ]
		then
			let fail++
		fi
	done
	let total=$success+$fail
	printf "time,port,project,$1,$total,$success,$fail\n" >> ${R_P_LOG_CAN}/ping_template.log 
}

can_ring_stress_error(){
	# can_ring stress test result find error
	local can_type=("BCAN" "PCAN" "CAN3" "CAN4")
	local error_info=$(grep -a error ${R_P_LOG_CAN}/can_stress.log)
	local ii
	for ((ii=0;ii<=3;ii++))
	do
		error_type=$(echo "${error_info}" |grep -a ${can_type[$ii]})
		error_status=$(echo "$error_type" |awk '{print $8}'|awk -F "." '{print $1}')
		can_ring_stress_statistic ${can_type[$ii]}
	done
}

can_ring_stress_1(){
	# main process : can ring test
	local delay_time=$(jq -r ".delay_time" ${SOURCE_PATH}/config.json)
	local can_cycle=$(jq -r ".para_can.can_cycle" ${SOURCE_PATH}/config.json)
	local test_init
	for ((test_init=1;test_init<=${can_cycle};test_init++))
	do
		sleep ${delay_time}
		can_ring_stress_error |tee -a ${R_P_LOG_CAN}/can_statistic.log
	done
}

can_main_stress(){
	can_dependency_package
	if [ ! -d ${R_P_LOG_CAN} ]
	then
		mkdir -p ${R_P_LOG_CAN}
	fi
	local can_mode=$(jq -r ".para_can.can_mode" ${SOURCE_PATH}/config.json)
	can_help_info_mode
	if [ "${can_mode}" -eq 1 ]
	then
		printf "Select can test mode is ${C_F_BLUE}${can_mode}${C_F_RES}\n"
		sleep 5
		/usr/bin/cutecom
	elif [ "${can_mode}" -eq 2 ]
	then
		printf "Select can test mode is ${C_F_BLUE}${can_mode}${C_F_RES}\n"
		sleep 5
		can_ring_stress_excute &
		can_ring_stress_1
	else
		printf "please check $SOURCE_PATH/config.json can_mode\n"
		exit 1
	fi
}
