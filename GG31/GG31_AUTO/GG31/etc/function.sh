#!/bin/bash
SOURCE_PATH=/home/worker/GG31
source ${SOURCE_PATH}/etc/common.sh

function_lever_first_master(){ 
	# head title : master port first level
	echo -e "\n${C_F_BLUE}-->>  Master_Port : Check $1${C_F_RES}\n"
}

function_lever_second_master(){
	# head title : master port secondary lever
	echo -e "${S_L_STR0// /-}\n\n\t${C_F_GREEN}-->>  Check $1${C_F_RES}\n\n${S_L_STR0// /-}"
}

function_lever_first_slave(){
	# head title : slave port first level title
	echo -e "\n${C_F_BLUE}-->>  Slave_Port : Check $1${C_F_RES}\n"
}

function_time_output(){
	# result : compare master/slave time sync
	a=$(date "+%Y%m%d%H%M")
	b=$(ssh slave date "+%Y%m%d%H%M")
	echo "${S_L_STR0// /-}"
	if [ "${a}" -eq "${b}" ]
	then 
		local state=""
	else
		local state="not"
	fi
	printf "${C_F_LINE}[ Check ] : The time ${state} synchronize ...${C_F_RES}\n"
}

function_time_sync(){
	# result : check master/slave/blackbox time sync
	printf "M_port time : $(date)\n"
	ssh ${P_I_SLAVE} "echo -e "S_port time : $(date)""
	ssh ${P_N_BB}@${P_I_BLACK} "echo -e "B_port time : $(date)""
	function_time_output
}

function_status_result(){
	# result : check command excute status
	if [ "$?" -eq 0 ]
	then
		let $1=$1+1
	else
		let $2=$2+1
	fi
}

function_progress_bar(){
	# progress bar $1 * 100 seconds
	printf "Waiting $1*100 seconds\n"
	local i str=""
	local index=0
	array=("|" "/" "-" "\\")
	for i in {0..100}
	do
		let index%=4
		printf "${C_F_GREEN} Progress: [%d%%]${C_F_RES} [%-100s] [\E[1;3${index}m%c${C_F_RES}]\r" "$i" "$str" "${array[$index]}"
		sleep $1
		let i++
		let index++
		str+='#'
	done
}
