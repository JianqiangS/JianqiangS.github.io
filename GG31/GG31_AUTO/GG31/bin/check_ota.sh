#!/bin/bash
# ===================================================================================
# GG31 system module : OTA
# ota module : check ota complete upgrade , patch upgrade , 
# ota module : check ota function , breakpoint transmission , data rollback
# ===================================================================================
source /home/worker/GG31/etc/common.sh
source /home/worker/GG31/etc/function.sh

check_ota_config_file(){
	# check ota config file 
	sudo cp ${OTA_PATH}/_ota_cli.pyc /usr/local/bin/
	cp ${OTA_PATH}/vid.json ${HOME}/config/
}

check_ota_complete_upgrade(){
	# check ota complete upgrade
	tx2i_master_first_lever "ota complete upgrade"
	echo "${STR// /-}"
	ota-client -f
	echo "${STR// /-}"
}

check_ota_patch_upgrade(){
	# check ota patch upgrade
	tx2i_master_first_lever "ota patch upgrade"
	echo "${STR// /-}"
	ota-client
	echo "${STR// /-}"
}

check_ota_function(){
	# check ota function
	tx2i_master_first_lever "ota function"
	tx2i_master_second_lever "compass version info"
	compass_version=$(dpkg -l |grep compass |awk '{print $3}')
	echo -e "${LINE}dpkg -l | grep compass${RES}"
	echo "uos compass version : $compass_version"
	tx2i_master_second_lever "ota install uos package"
	uos_version=$(strings ${HOME}/uos/run/bin/uos_daemon | grep 2019)
	echo -e "${LINE}strings uos_daemon${RES}"
	echo "uos package : $uos_version"
	tx2i_master_second_lever "verify MD5 value"
	cd ${HOME}/uos/run
	success=$(md5sum -c md5sum.log | grep -c OK)
	fail=$(md5sum -c md5sum.log | grep -c FAILED)
	echo -e "${LINE}md5sum -c md5sum.log${RES}"
	echo "Verify md5sum.log value : success ${success} ; fail ${fail}"
	echo "${STR// /-}"
}

check_ota_upgrade_environment(){
	# check ota upgrade environment
	ping -c5 ${NPORT} > /dev/null
	if [ $? -eq 0 ]
	then
		ifconfig wlan0 > /dev/null
		if [ $? -eq 0 ]
		then
			echo -e "${LINE}[ Check ] : wifi environment does not support ota upgrade ...${RES}"
			exit 2
		fi 
	else
		echo -e "${LINE}[ Check ] : network issue ...${RES}"
		exit 1
	fi
}

check_ota(){
	# check ota module all function
	check_ota_upgrade_environment
	check_ota_config_file
	check_ota_complete_upgrade
	check_ota_function
	check_ota_patch_upgrade
	check_ota_function
}
