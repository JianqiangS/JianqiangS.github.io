#!/bin/bash
SOURCE_PATH=/home/worker/GG31_SYSTEM

service_iperf_pid(){
	{
	sleep 10
	ps -ef |grep monitor_iperf |grep -v grep |awk '{print $2}'
	} > /var/run/module_iperf.pid
}

service_iperf_start(){
	source ${SOURCE_PATH}/bin/monitor_iperf.sh
	service_iperf_pid &
	iperf_main_stress	
}

service_iperf_stop(){
	local iperf_pid=$(cat /var/run/module_iperf.pid) 
	if [ -n "${iperf_pid}" ]
	then
		sudo kill -9 ${iperf_pid} 
	fi
}

case "$1" in
	start)
		service_iperf_start
	;;
	stop)
		service_iperf_stop
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
