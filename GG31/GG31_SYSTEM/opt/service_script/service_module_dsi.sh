#!/bin/bash
SOURCE_PATH=/home/worker/GG31_SYSTEM

service_dsi_pid(){
	{
	sleep 10
	ps -ef |grep monitor_dsi |grep -v grep |awk '{print $2}'
	} > /var/run/module_dsi.pid
}

service_dsi_start(){
	source ${SOURCE_PATH}/bin/monitor_module/monitor_dsi.sh
	service_dsi_pid &
	dsi_main_stress	
}

service_dsi_stop(){
	local dsi_pid=$(cat /var/run/module_dsi.pid) 
	if [ -n "${dsi_pid}" ]
	then
		sudo kill -9 ${dsi_pid} 
	fi
}

case "$1" in
	start)
		service_dsi_start
	;;
	stop)
		service_dsi_stop
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
