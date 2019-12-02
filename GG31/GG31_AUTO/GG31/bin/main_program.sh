#!/bin/bash
SOURCE_PATH=/home/worker/GG31
source ${SOURCE_PATH}/etc/common.sh
source ${SOURCE_PATH}/etc/function.sh

get_send_mail(){
	#uuencode ${log} ${DATE}_gg31_test.log | mail -s "`date "+%F %T"` ${hw_type} OSv${sw_v_os} System Test Result" 13734716682@163.com
	#mail -s "`date "+%F %T"` ${hw_type} OSv${sw_v_os} System Test Result" 13734716682@163.com < ${r_p_log}/gg_test.log
	{
	uuencode ${r_p_log}/gg_test.log ${DATE}_gg31_test.log
	} | mail -s "`date "+%F %T"` ${hw_type} OSv${sw_v_os} System Test Result" 13734716682@163.com < ${r_p_log}/gg_test.log
}

get_unit_status(){
	# from json file get per module test switch
	local unit_switch=$(jq $1 ${SOURCE_PATH}/config.json)
	if [ "${unit_switch}" -eq 1 ]
	then
		source ${SOURCE_PATH}/bin/$2.sh
		$2
	fi
}

get_unit_test(){
	case $1 in
		"check_apu")
			get_unit_status ".switch_apu" "check_apu"
		;;
		"check_bb")
			get_unit_status ".switch_bb" "check_bb"
		;;
		"check_cdu")
			get_unit_status ".switch_cdu" "check_cdu"
		;;
		"check_dgps")
			get_unit_status ".switch_dgps" "check_dgps"
		;;
		"check_net")
			get_unit_status ".switch_net" "check_net"
		;;
		"check_ioin")
			get_unit_status ".switch_ioin" "check_ioin"
		;;
		"check_ioout")
			get_unit_status ".switch_ioout" "check_ioout"
		;;
		"check_ota")
			get_unit_status ".switch_ota" "check_ota"
		;;
		"check_power")
			get_unit_status ".switch_power" "check_power"
		;;
		"check_tx2i")
			get_unit_status ".switch_tx2i" "check_tx2i"
		;;
		"check_all")
			get_unit_status ".switch_tx2i" "check_tx2i"
			get_unit_status ".switch_net" "check_net"
			get_unit_status ".switch_apu" "check_apu"
			get_unit_status ".switch_cdu" "check_cdu"
			get_unit_status ".switch_ioin" "check_ioin"
			get_unit_status ".switch_ioout" "check_ioout"
			get_unit_status ".switch_dgps" "check_dgps"
			get_unit_status ".switch_ota" "check_ota"
			get_unit_status ".switch_power" "check_power"
			get_unit_status ".switch_bb" "check_bb"
		;;
		*)
			exit 1
		;;
	esac
}

get_gg_test_excute(){
	local excute_num=$(jq '.excute_num' ${SOURCE_PATH}/config.json)
	for ((i=1;i<=${excute_num};i++))
	do
		printf "$(date "+%F %T") : ${hw_type} OSv${sw_v_os} system test\n"
		if [ "${excute_num}" -gt 1 ]
		then
			printf "$(date "+%F %T") : the ${i} times"
		fi
		get_unit_test $1
	done
	printf "${C_F_LINE}[ Result ] : Log saved to ${r_p_log}${C_F_RES}\n"
	get_send_mail
}

get_gg_test(){
	# main process
	local hw_type=$(jq '.para_version.hw_type' ${SOURCE_PATH}/config.json)
	local sw_v_os=$(jq '.para_version.sw_v_os' ${SOURCE_PATH}/config.json)
	r_p_log=${R_P_LOG}/${D_FORMAT}
	if [ ! -d "${r_p_log}" ]
	then
		mkdir -p ${r_p_log}
	fi
	get_gg_test_excute $1 |tee -a ${r_p_log}/gg_test.log
}

get_gg_test $1
