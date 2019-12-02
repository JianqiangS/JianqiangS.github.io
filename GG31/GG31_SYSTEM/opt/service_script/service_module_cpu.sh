#!/bin/bash
SOURCE_PATH=/home/worker/GG31_SYSTEM

service_cpu_pid(){
	{
	sleep 10
	ps -ef |grep monitor_cpu |grep -v grep |awk '{print $2}'
	} > /var/run/module_cpu.pid
}

service_cpu_start(){
	source ${SOURCE_PATH}/bin/monitor_cpu.sh
	service_cpu_pid &
	cpu_main_stress	
}

service_cpu_stop(){
	local cpu_pid=$(cat /var/run/module_cpu.pid) 
	if [ -n "${cpu_pid}" ]
	then
		sudo kill -9 ${cpu_pid} 
	fi
}

case "$1" in
	start)
		service_cpu_start
	;;
	stop)
		service_cpu_stop
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
