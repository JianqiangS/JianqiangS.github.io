#!/bin/bash
SOURCE_PATH=/home/worker/GG31
source ${SOURCE_PATH}/etc/common.sh
source ${SOURCE_PATH}/etc/function.sh

check_apu_upgrade_updata(){
	# upgrade apu with updata_apu method
	function_lever_second_master "updata_apu ($1/$2)"
	./updata_apu.sh /dev/ttyTHS2 $1/$2
}

check_apu_upgrade_burn(){
	# upgrade apu with burn_apu method
	function_lever_second_master "burn_apu ($1/$2)"
	burn_apu.sh -f $1/$2
}

check_apu_soft_version(){
	# Read apu software version
	function_lever_second_master "apu software version"
	python3 ${F_P_APU_HOST}/apu_info.py
}

check_apu_hard_version(){
	# Read apu software version
	function_lever_second_master "apu hardware version"
	python3 ${F_P_APU_HOST}/apu_hwversion.py
}

check_apu_updata_template(){
	# apu updgrade with updata method template
	if [ -d "$1" ]
	then
		# upgrade e100 apu by updata method 
		for ((i=1;i<=2;i++))
		do
			check_apu_upgrade_updata "$1" "${F_N_APU_E100}"
			check_apu_soft_version
			check_apu_hard_version
		done

		# upgrade e100w apu by updata method 
		for ((i=1;i<=2;i++))
		do
			check_apu_upgrade_updata "$1" "${F_N_APU_E100W}"
			check_apu_soft_version
			check_apu_hard_version
		done
	else
		printf "$1 directory error or not exist...\n"
	fi
}

check_apu_burn_template(){
	# apu updgrade with burn method template
	if [ -d "$1" ]
	then
		# upgrade e100 apu by burn method 
		for ((i=1;i<=2;i++))
		do
			check_apu_upgrade_burn "$1" "${F_N_APU_E100}"
			check_apu_soft_version
			check_apu_hard_version
		done

		# upgrade e100w apu by burn method 
		for ((i=1;i<=2;i++))
		do
			check_apu_upgrade_burn "$1" "${F_N_APU_E100W}"
			check_apu_soft_version
			check_apu_hard_version
		done
	else
		printf "$1 directory error or not exist...\n"
	fi
}

check_apu_updata(){
	cd ${F_P_APU_HOST}
	# upgrade target path : ~/firmware/APU/target
	check_apu_updata_template "${F_P_APU_TARGET}"

	# upgrade target path : ~/uisee_xxxx/run/bin/apu
	#check_apu_updata_template "${uisee_apu_path}"

	# upgrade target path : ~/uos/run/bin/apu
	check_apu_updata_template "${uos_apu_path}"
}

check_apu_burn(){
	cd ${F_P_HOME}
	# upgrade target path : ~/firmware/APU/target
	check_apu_burn_template "${F_P_APU_TARGET}"

	# upgrade target path : ~/uisee_xxxx/run/bin/apu
	#check_apu_burn_template "${uisee_apu_path}"

	# upgrade target path : ~/uos/run/bin/apu
	#check_apu_burn_template "${uos_apu_path}"
}

check_apu_upgrade(){
	function_lever_first_master "apu upgrade"
	check_apu_updata
	check_apu_burn
	echo -e "${S_L_STR0// /-}\n"
}

check_apu_correct_template(){
	if [ -d "$1" ]
	then
		function_lever_second_master "$1 correctness"
		cd $1 && . set_env.sh
		timeout 1 ./bin/vstream-test -c /dev/ttyTHS2
	else
		printf "$1 directory error or not exist...\n"
	fi
}

check_apu_correct(){
	function_lever_first_master "apu correctness"
	check_apu_correct_template "${uisee_run_path}"
	#check_apu_correct_template "${uos_run_path}"
	echo -e "${S_L_STR0// /-}\n"
}

check_apu_param_template(){
	if [ -d "$1" ]
	then
		cd $1
		function_lever_second_master "$1/uos_apu.json content"
		cat uos_apu.json
		function_lever_second_master "$1/uos_apu.json verification"
		chmod +x apu_conf.py
		timeout 5 ./apu_conf.py uos_apu.json /dev/ttyTHS2
	else
		printf "$1 directory error or not exist...\n"
	fi
}

check_apu_param(){
	function_lever_first_master "apu parameter"
	check_apu_param_template "${uisee_apu_path}"
	check_apu_param_template "${uos_apu_path}"
	echo -e "${S_L_STR0// /-}\n"
}

check_apu(){
	local uisee_name=$(jq -r ".set_uos_name" ${SOURCE_PATH}/config.json)
	local uisee_apu_path=${F_P_HOME}/${uisee_name}/run/bin/apu
	local uisee_run_path=${F_P_HOME}/${uisee_name}/run
	local uos_apu_path=${F_P_HOME}/uos/run/bin/apu
	local uos_run_path=${F_P_HOME}/uos/run
	check_apu_upgrade && sleep 2
	check_apu_correct && sleep 2
	check_apu_param && sleep 2
}
