#!/bin/bash
SOURCE_PATH=/home/worker/GG31_SYSTEM

service_dgps_pid(){
	{
	sleep 10
	ps -ef |grep monitor_dgps |grep -v grep |awk '{print $2}'
	} > /var/run/module_dgps.pid
}

service_dgps_start(){
	source ${SOURCE_PATH}/bin/monitor_module/monitor_dgps.sh
	service_dgps_pid &
	dgps_main_stress	
}

service_dgps_stop(){
	local dgps_pid=$(cat /var/run/module_dgps.pid) 
	if [ -n "${dgps_pid}" ]
	then
		sudo kill -9 ${dgps_pid} 
	fi
}

case "$1" in
	start)
		service_dgps_start
	;;
	stop)
		service_dgps_stop
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
