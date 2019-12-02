#!/bin/bash
SOURCE_PATH=/home/worker/GG31_SYSTEM
source ${SOURCE_PATH}/etc/common.sh

service_help_info(){
	printf "service_switch_mode [0/1]\n"
	printf "\t"service_switch_mode": 0 , means ${C_F_BLUE}enable${C_F_RES} monitor_module.service\n"
	printf "\t"service_switch_mode": 1 , means ${C_F_BLUE}disable${C_F_RES} monitor_module.service\n"
	printf "\t"service_switch_mode": 2 , means ${C_F_BLUE}status${C_F_RES} monitor_module.service\n"
}

service_disable_template(){
	# disable monitor_module_xxx.service template
	if [ -f "${F_P_SYSTEM}/$1" ]
	then
		sudo systemctl stop $1
		sudo systemctl disable $1
	fi
}

service_disable_module(){
	# disable monitor_module_xxx.service
	service_disable_template "${monitor_apu}"
	service_disable_template "${monitor_can}"
	service_disable_template "${monitor_cdu}"	
	service_disable_template "${monitor_cpu}"
	service_disable_template "${monitor_dgps}"
	service_disable_template "${monitor_dsi}"
	service_disable_template "${monitor_gpu}"
	service_disable_template "${monitor_iperf}"
	service_disable_template "${monitor_net}"
	service_disable_template "${monitor_temp}"
	sleep 2 && sync
}

service_enable_template(){
	# enable monitor_module_xxx.service template
	if [ -f "${F_P_SYSTEM}/$1" ]
	then
		sudo systemctl enable $1
		sudo systemctl start $1
	fi
}

service_enable_module(){
	# enable monitor_module_xxx.service
	service_enable_template "${monitor_apu}"
	service_enable_template "${monitor_can}"
	service_enable_template "${monitor_cdu}"	
	service_enable_template "${monitor_cpu}"
	service_enable_template "${monitor_dgps}"
	service_enable_template "${monitor_dsi}"
	service_enable_template "${monitor_gpu}"
	service_enable_template "${monitor_iperf}"
	service_enable_template "${monitor_net}"
	service_enable_template "${monitor_temp}"
	sleep 2 && sync
}

service_status_template(){
	# check monitor_module_xxx.service status template
	if [ -f "${F_P_SYSTEM}/$1" ]
	then
		systemctl status $1 |head -12
		printf "\n"
	fi
}

service_status_module(){
	# monitor_module_xxx.service status
	service_status_template "${monitor_apu}"
	service_status_template "${monitor_can}"
	service_status_template "${monitor_cdu}"	
	service_status_template "${monitor_cpu}"
	service_status_template "${monitor_dgps}"
	service_status_template "${monitor_dsi}"
	service_status_template "${monitor_gpu}"
	service_status_template "${monitor_iperf}"
	service_status_template "${monitor_net}"
	service_status_template "${monitor_temp}"
}

service_file_template(){
	# check service file template
	if [ ! -f "${F_P_SYSTEM}/$1" ]
	then
		sudo cp ${R_P_OPT}/service_system/$1 ${F_P_SYSTEM}
	fi
}

service_file_copy(){
	# copy service file from ${R_P_ETC_SERVICE} to ${F_P_SYSTEM}
	service_file_template "${monitor_apu}"
	service_file_template "${monitor_can}"
	service_file_template "${monitor_cdu}"
	service_file_template "${monitor_cpu}"
	service_file_template "${monitor_dgps}"
	service_file_template "${monitor_dsi}"
	service_file_template "${monitor_gpu}"
	service_file_template "${monitor_iperf}"
	service_file_template "${monitor_net}"
	service_file_template "${monitor_temp}"
}

service_switch(){
	local monitor_apu=monitor_module_apu.service
	local monitor_can=monitor_module_can.service
	local monitor_cdu=monitor_module_cdu.service
	local monitor_cpu=monitor_module_cpu.service
	local monitor_dgps=monitor_module_dgps.service
	local monitor_dsi=monitor_module_dsi.service
	local monitor_gpu=monitor_module_gpu.service
	local monitor_iperf=monitor_module_iperf.service
	local monitor_net=monitor_module_net.service
	local monitor_temp=monitor_module_temp.service
	service_file_copy
	service_help_info
	if [ "$#" -ne 1 ]
	then
		exit 1
	fi	
	if [ ! "$1" -eq 0 ] && [ ! "$1" -eq 1 ] && [ ! "$1" -eq 2 ]
	then
		exit 1
	fi

	if [ "$1" -eq 0 ]
	then
		printf "Select service_switch_mode is "$1"\n"
		sleep 2 && service_enable_module	
		printf "[${C_F_BLUE}Note${C_F_RES}] : \"ssh slave sudo reboot; reboot\" to enable setting\n"
	elif [ "$1" -eq 1 ]
	then
		printf "Select service_switch_mode is "$1"\n"
		sleep 2	&& service_disable_module
		printf "[${C_F_BLUE}Note${C_F_RES}] : \"ssh slave sudo reboot; reboot\" to enable setting\n"
	elif [ "$1" -eq 2 ]
	then
		printf "Select service_switch_mode is "$1"\n"
		sleep 2 && service_status_module
	else
		printf "Please input value error ...\n"
		exit 2
	fi
}

service_switch $1	
