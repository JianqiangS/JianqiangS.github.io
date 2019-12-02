#!/bin/bash
SOURCE_PATH=/home/worker/GG31_SYSTEM
source ${SOURCE_PATH}/etc/common.sh
source ${SOURCE_PATH}/etc/function.sh
source ${SOURCE_PATH}/etc/install_deb.sh

monitor_result_status(){
	# monitor result status 
	if [ "$?" -eq 0 ]
	then
		status="$1"
	else
		status="$2"
	fi
}

monitor_hwaddr(){
	# output eth0 address
	function_eth0_hwaddr
	printf "project,eth0,hwaddr,/,${eth0_hwaddr}\n"
}

monitor_version(){
	# output version info 
	function_version_info
	printf "project,hardware,platform,/,${version_hw_platform}\n"
	printf "project,kernal,release,/,V${version_hw_kernal}\n"
	printf "project,uisee_os,release,/,V${version_sw_os}\n"
	printf "project,uisee_apu,release,/,V${version_sw_apu}\n"
}

monitor_time(){
	# view current time 
	printf "project,time,date,/,$(date "+%F %T")\n"
}

monitor_net_huawei(){
	# check whether the Huawei module is in place
	local status
	lsusb | grep -i huawei > ${C_D_NULL}
	monitor_result_status "ON" "OFF"
	printf "project,network,huawei,/,${status}\n"
}

monitor_net_ttyusb0(){
	# check if 4G nodes exist
	local status
	ls /dev/ttyUSB0 > ${C_D_NULL}
	monitor_result_status "ON" "OFF"
	printf "project,network,ttyusb0,/,${status}\n"
}

monitor_net_ping_ip(){
	# check network with ping ip method
	local status
	ping -c ${ping_package_num} -i ${ping_package_time} ${ping_package_ip} > ${C_D_NULL} 2>&1
	monitor_result_status "ON" "OFF"
	printf "project,network,ping_ip,/,${status}\n"
}

monitor_net_ping_domain(){
	# check network with ping domain name method
	local status
	ping -c ${ping_package_num} -i ${ping_package_time} ${ping_package_domain} > ${C_D_NULL} 2>&1
	monitor_result_status "ON" "OFF"
	printf "project,network,ping_domain,/,${status}\n"
}

monitor_net(){
	# check network status
	local ping_package_num=$(jq -r ".para_net.ping_package.ping_num" ${SOURCE_PATH}/config.json)
	local ping_package_time=$(jq -r ".para_net.ping_package.ping_time" ${SOURCE_PATH}/config.json)
	local ping_package_ip=$(jq -r ".para_net.ping_package.ping_ip" ${SOURCE_PATH}/config.json)
	local ping_package_domain=$(jq -r ".para_net.ping_package.ping_domain" ${SOURCE_PATH}/config.json)
	monitor_net_huawei
	monitor_net_ttyusb0
	monitor_net_ping_ip
	monitor_net_ping_domain
}

monitor_cpu(){
	# check cpu status
	local cpu_info=$(sudo timeout 2 /home/worker/tegrastats)
	local cpu_info_0=$(echo "$cpu_info" |tail -1 |awk '{print $6}')
	local cpu_info_1=$(echo "$cpu_info_0" |tr -d "[]")
	for ((i=1;i<=6;i++))
	do
		per_cpu=$(echo "$cpu_info_1" |awk -F "," '{print $'"$i"'}')
		echo "$per_cpu" |grep -i off > ${C_D_NULL}
		monitor_result_status "OFF" "ON"
		per_cpu_rate=$(echo "$per_cpu" |awk -F "%" '{print $1}')
		per_cpu_freq=$(echo "$per_cpu" |awk -F "@" '{print $2}')
		printf "project,cpu,cpu$i,status,${status}\n"
		printf "project,cpu,cpu$i,rate,${per_cpu_rate}%%\n"
		printf "project,cpu,cpu$i,frequency,${per_cpu_freq}MHZ\n"
	done
}

monitor_gpu(){
	# check gpu status
	local gpu_info=$(sudo timeout 2 /home/worker/tegrastats)
	function_gpu_status_info "${gpu_info}"
	printf "project,gpu,rate,/,${gpu_rate}%%\n"
	printf "project,gpu,frequency,/,${gpu_freq}MHZ\n"
}

monitor_loadavg(){
	# check system loadaverage
	local loadavg_info=$(cat /proc/loadavg)
	local loadavg_1=$(echo "${loadavg_info}" |awk '{print $1}')
	local loadavg_10=$(echo "${loadavg_info}" |awk '{print $2}')
	local loadavg_15=$(echo "${loadavg_info}" |awk '{print $3}')
	printf "project,loadavg,1min,/,${loadavg_1}\n"
	printf "project,loadavg,10min,/,${loadavg_10}\n"
	printf "project,loadavg,15min,/,${loadavg_15}\n"
}

monitor_disk_home(){
	# check disk home directory size
	local disk_home_info=$(df -h |grep -m1 home)
	local disk_home_total=$(echo "${disk_home_info}" |awk '{print $2}')
	local disk_home_free=$(echo "${disk_home_info}" |awk '{print $4}')
	printf "project,disk,home,total_size,${disk_home_total}\n"
	printf "project,disk,home,free_size,${disk_home_free}\n"
}

monitor_disk_root(){
	# check disk root directory size
	local disk_root_info=$(df -h |grep -m1 root)
	local disk_root_total=$(echo "${disk_root_info}" |awk '{print $2}')
	local disk_root_free=$(echo "${disk_root_info}" |awk '{print $4}')
	printf "project,disk,root,total_size,${disk_root_total}\n"
	printf "project,disk,root,free_size,${disk_root_free}\n"
}

monitor_disk(){
	# check disk size
	monitor_disk_home
	monitor_disk_root
}

monitor_ram(){
	# check ram size
	local ram_info=$(free -h |grep -i Mem)
	local ram_total=$(echo "${ram_info}" |awk '{print $2}')
	local ram_free=$(echo "${ram_info}" |awk '{print $4}')
	printf "project,ram,total_size,/,${ram_total}\n"
	printf "project,ram,free_size,/,${ram_free}\n"
}

monitor_result_video(){
	if [ "$1" -eq 1 ]
	then
		status="ON"
	else
		status="OFF"
	fi
	printf "project,video,$2,status,${status}\n"
}

monitor_video(){
	# check video status
	function_video0_lock_status
	function_video1_lock_status
	monitor_result_video ${port0_lock_sts} video0
	monitor_result_video ${port1_lock_sts} video1
	monitor_result_video ${port2_lock_sts} video2
	monitor_result_video ${port3_lock_sts} video3
	monitor_result_video ${port4_lock_sts} video4
	monitor_result_video ${port5_lock_sts} video5
	monitor_result_video ${port6_lock_sts} video6
	monitor_result_video ${port7_lock_sts} video7
}

monitor_power_template(){
	grep $1 $2 | grep $3 > ${C_D_NULL}
	monitor_result_status "ON" "OFF"
	printf "project,power,$1,status,${status}\n"
}

monitor_power(){
	module_power_ctrl.sh diag > ${R_P_LOG_MONITOR}/power_info.log
	monitor_power_template "4g" ${R_P_LOG_MONITOR}/power_info.log "enable"
	monitor_power_template "wifi" ${R_P_LOG_MONITOR}/power_info.log "enable"
	monitor_power_template "dgps" ${R_P_LOG_MONITOR}/power_info.log "enable"
	monitor_power_template "lidar" ${R_P_LOG_MONITOR}/power_info.log "enable"
	monitor_power_template "camera-964" ${R_P_LOG_MONITOR}/power_info.log "enable"
	monitor_power_template "gmsl" ${R_P_LOG_MONITOR}/power_info.log "enable"
	monitor_power_template "1g_switch" ${R_P_LOG_MONITOR}/power_info.log "enable"
	monitor_power_template "lidar_switch" ${R_P_LOG_MONITOR}/power_info.log "enable"
}

monitor_system_status(){
	# monitor system status : all module
	printf "project,name,first,second,result\n" 
	monitor_time
	monitor_version
	monitor_hwaddr
	monitor_net
	monitor_cpu
	monitor_gpu
	monitor_loadavg
	monitor_disk
	monitor_ram
	monitor_video
	monitor_power
}

monitor_dependency_package(){
	# dependency package installation
	install_deb_check "csvlook" install_deb_csvkit
	install_deb_check "firefox" install_deb_firefox
	install_deb_check "mail" install_deb_heirloom_mailx
	install_deb_check "uuencode" install_deb_uuencode 
}

monitor_output_html(){
	local head_m="GG3.1 system status monitor"
	local system_info=$(csvlook ${R_P_LOG_MONITOR}/system_monitor.log)
	echo "
	<!doctype html>
	<html>
		<head>
			<meta charset="utf-8">
			<title>system status monitor</title>
			<link rel="icon" type="image/x-icon" href="${R_P_LIB_HTML}/uisee.png">
			<link rel="stylesheet" type="text/css" href="${R_P_LIB_HTML}/html_style.css">
		</head>
		<body>
			<div>
				<hr />
				<h1>${head_m}</h1>
				<hr />
				<pre>${system_info}</pre>
				<hr />
			</div>
		</body>
	</html>
	" > ${R_P_LOG_MONITOR}/system_monitor.html
	timeout 30 firefox ${R_P_LOG_MONITOR}/system_monitor.html > ${C_D_NULL} 2>&1
}

monitor_system_show(){
	# monitor system status and show status info
	monitor_dependency_package
	if [ ! -d ${R_P_LOG_MONITOR} ]
	then
		mkdir -p ${R_P_LOG_MONITOR}
	fi
	monitor_system_status > ${R_P_LOG_MONITOR}/system_monitor.log
	monitor_output_html
	mail -s "GG3.1 system monitor information" 13734716682@163.com < ${R_P_LOG_MONITOR}/system_monitor.log
}
