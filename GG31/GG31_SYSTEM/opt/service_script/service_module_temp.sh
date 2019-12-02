#!/bin/bash
SOURCE_PATH=/home/worker/GG31_SYSTEM

service_temp_pid(){
	{
	sleep 10
	ps -ef |grep monitor_temp |grep -v grep |awk '{print $2}'
	} > /var/run/module_temp.pid
}

service_temp_start(){
	source ${SOURCE_PATH}/bin/monitor_temp.sh
	service_temp_pid &
	temp_main_stress	
}

service_temp_stop(){
	local temp_pid=$(cat /var/run/module_temp.pid) 
	if [ -n "${temp_pid}" ]
	then
		sudo kill -9 ${temp_pid} 
	fi
}

case "$1" in
	start)
		service_temp_start
	;;
	stop)
		service_temp_stop
	;;
	restart)
		$0 stop
		$0 start
	;;
	*)
		printf "unsupported argument 1 : $1\n"
		exit 1
	;;
esac
