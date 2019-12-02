#!/bin/bash
SOURCE_PATH=/home/worker/GG31_SYSTEM

service_apu_pid(){
	{
	sleep 10
	ps -ef |grep monitor_apu |grep -v grep |awk '{print $2}'
	} > /var/run/module_apu.pid
}

service_apu_start(){
	source ${SOURCE_PATH}/bin/monitor_module/monitor_apu.sh
	service_apu_pid &
	apu_main_stress	
}

service_apu_stop(){
	local apu_pid=$(cat /var/run/module_apu.pid) 
	if [ -n "${apu_pid}" ]
	then
		sudo kill -9 ${apu_pid} 
	fi
}

case "$1" in
	start)
		service_apu_start
	;;
	stop)
		service_apu_stop
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
