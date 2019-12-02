#!/bin/bash
SOURCE_PATH=/home/worker/GG31_SYSTEM

service_net_pid(){
	{
	sleep 10
	ps -ef |grep monitor_net |grep -v grep |awk '{print $2}'
	} > /var/run/module_net.pid
}

service_net_start(){
	source ${SOURCE_PATH}/bin/monitor_net.sh
	service_net_pid &
	net_main_stress	
}

service_net_stop(){
	local net_pid=$(cat /var/run/module_net.pid) 
	if [ -n "${net_pid}" ]
	then
		sudo kill -9 ${net_pid} 
	fi
}

case "$1" in
	start)
		service_net_start
	;;
	stop)
		service_net_stop
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
