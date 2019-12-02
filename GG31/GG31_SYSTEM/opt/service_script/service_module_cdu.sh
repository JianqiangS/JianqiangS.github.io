#!/bin/bash
SOURCE_PATH=/home/worker/GG31_SYSTEM

service_cdu_pid(){
	{
	sleep 10
	ps -ef |grep monitor_cdu |grep -v grep |awk '{print $2}'
	} > /var/run/module_cdu.pid
}

service_cdu_start(){
	source ${SOURCE_PATH}/bin/monitor_module/monitor_cdu.sh
	service_cdu_pid &
	cdu_main_stress	
}

service_cdu_stop(){
	local cdu_pid=$(cat /var/run/module_cdu.pid) 
	if [ -n "${cdu_pid}" ]
	then
		sudo kill -9 ${cdu_pid} 
	fi
}

case "$1" in
	start)
		service_cdu_start
	;;
	stop)
		service_cdu_stop
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
