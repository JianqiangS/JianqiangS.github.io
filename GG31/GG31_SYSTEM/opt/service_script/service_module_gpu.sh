#!/bin/bash
SOURCE_PATH=/home/worker/GG31_SYSTEM

service_gpu_pid(){
	{
	sleep 10
	ps -ef |grep monitor_gpu |grep -v grep |awk '{print $2}'
	} > /var/run/module_gpu.pid
}

service_gpu_start(){
	source ${SOURCE_PATH}/bin/monitor_gpu.sh
	service_gpu_pid &
	gpu_main_stress	
}

service_gpu_stop(){
	local gpu_pid=$(cat /var/run/module_gpu.pid) 
	if [ -n "${gpu_pid}" ]
	then
		sudo kill -9 ${gpu_pid} 
	fi
}

case "$1" in
	start)
		service_gpu_start
	;;
	stop)
		service_gpu_stop
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
