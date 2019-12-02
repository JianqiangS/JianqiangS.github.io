#!/bin/bash
SOURCE_PATH=/home/worker/GG31_SYSTEM
source ${SOURCE_PATH}/etc/common.sh
source ${SOURCE_PATH}/etc/install_deb.sh

net_dependency_package(){
	# dependency package installation
	install_deb_check "csvlook" install_deb_csvkit
	install_deb_check "firefox" install_deb_firefox
	install_deb_check "gnuplot" install_deb_gnuplot
}

net_help_info(){
	# network ping mode ip or domain
	printf "Ping_mode [1/2]\n"
	printf "\t\"ping_mode\": 1 , correspond ping_package_ip (${ping_package_ip})\n"
	printf "\t\"ping_mode\": 2 , correspond ping_package_domain (${ping_package_domain})\n"
}

net_main_stress_type(){
	# network stress test template
	local delay_time=$(jq -r ".delay_time" ${SOURCE_PATH}/config.json)
	local ping_cycle=$(jq -r ".para_net.ping_cycle" ${SOURCE_PATH}/config.json)
	local ping_package_num=$(jq -r ".para_net.ping_package.ping_num" ${SOURCE_PATH}/config.json)
	local ping_package_time=$(jq -r ".para_net.ping_package.ping_time" ${SOURCE_PATH}/config.json)
	local ping_show_image=$(jq -r ".para_net.ping_image.show_interval" ${SOURCE_PATH}/config.json)
	local ping_switch_image=$(jq -r ".para_net.ping_image.show_switch" ${SOURCE_PATH}/config.json)
	local ping_success=0 ping_lost=0 ping_fail=0
	local receve cycle test_init
	for ((test_init=1;test_init<=${ping_cycle};test_init++))
	do
		ping -c ${ping_package_num} -i ${ping_package_time} $1 |tee ${R_P_LOG_NETWORK}/ping.log > ${C_D_NULL} 2>&1
		net_result_statistic $1
		let cycle=${test_init}%${ping_show_image}
		if [ "${cycle}" -eq 0 ]
		then
			net_output_png
			net_output_html
			if [ "${ping_switch_image}" -eq 1 ]
			then
				timeout 20 firefox ${R_P_LOG_NETWORK}/net_monitor.html > ${C_D_NULL} 2>&1
			fi
		fi
		sleep ${delay_time}
	done
}

net_result_statistic(){
	# check network test result
	if [ -s ${R_P_LOG_NETWORK}/ping.log ]
	then
		receve=$(grep -a received ${R_P_LOG_NETWORK}/ping.log |awk -F "," '{print $2}'|awk -F " " '{print $1}')
		if [ "${receve}" -eq 0 ]
		then
			let ping_fail=${ping_fail}+1
		elif [ "${receve}" -gt 0 ] && [ "${receve}" -lt ${ping_package_num} ]
		then
			let ping_lost=${ping_lost}+1
		elif [ "${receve}" -eq ${ping_package_num} ]
		then
			let ping_success=${ping_success}+1
		else
			let ping_fail=${ping_fail}+1
		fi
	else
		let ping_fail=${ping_fail}+1
	fi
	{
	printf "time,project,sub_project,test_num,success_num,lost_num,fail_num\n"
	printf "$(date "+%F %T"),net,$1,${test_init},${ping_success},${ping_lost},${ping_fail}\n" 
	} > ${R_P_LOG_NETWORK}/ping_template.log
	csvlook ${R_P_LOG_NETWORK}/ping_template.log
	tail -1 ${R_P_LOG_NETWORK}/ping_template.log >> ${R_P_LOG_NETWORK}/ping_statistic.log
}

net_output_png(){
	echo "
	set terminal png size 1080,720
	set output \"$R_P_LOG_NETWORK/ping.png\"
	set border lc rgb \"orange\"
	set xlabel \"times\" font \",16\"
	set ylabel \"frequency\" font \",16\"
	set xrange [-2:$test_init]
	set yrange [-2:$test_init]
	set grid x,y lc rgb \"orange\"
	set key box reverse
	set datafile sep ','
	plot \"$R_P_LOG_NETWORK/ping_statistic.log\" u 5 w l lc 1 lw 2 t \"NET: Receive-A\",\
	'' u 6 w l lc 6 lw 2 t \"NET: Receive-P\",\
	'' u 7 w l lc 7 lw 2 t \"NET: Receive-Z\" " |gnuplot
}

net_output_html(){
	local time_s=$(awk -F "," '{print $1}' ${R_P_LOG_NETWORK}/ping_statistic.log |head -1)
	local time_e=$(awk -F "," '{print $1}' ${R_P_LOG_NETWORK}/ping_statistic.log |tail -1)
	local head_m="GG3.1 network status monitor (${time_s} to ${time_e})"
	local net_info=$(csvlook ${R_P_LOG_NETWORK}/ping_template.log)
	echo "
	<!DOCTYPE html>
	<html>
		<head>
			<meta charset="utf-8">
			<title>network status monitor</title>
			<link rel="icon" type="image/x-icon" href="${R_P_LIB_HTML}/uisee.png">
			<link rel="stylesheet" type="text/css" href="${R_P_LIB_HTML}/html_style.css">
		</head>
		<body>
			<div>
				<hr />
				<h2>${head_m}</h2>
				<hr />
				<pre>${net_info}</pre>
				<hr />
			</div>
			<div>
				<hr />
				<img src="${R_P_LOG_NETWORK}/ping.png">
				<hr />
			</div>
		</body>
	</html>
	" > ${R_P_LOG_NETWORK}/net_monitor.html
}

net_main_stress(){
	# network stress test
	net_dependency_package
	if [ ! -d ${R_P_LOG_NETWORK} ]
	then
		mkdir -p ${R_P_LOG_NETWORK}
	fi
	local ping_package_type=$(jq -r ".para_net.ping_package.ping_mode" ${SOURCE_PATH}/config.json)
	local ping_package_ip=$(jq -r ".para_net.ping_package.ping_ip" ${SOURCE_PATH}/config.json)
	local ping_package_domain=$(jq -r ".para_net.ping_package.ping_domain" ${SOURCE_PATH}/config.json)
	net_help_info
	if [ "${ping_package_type}" -eq 1 ]
	then
		# network IP connectivity verification 
		printf "Select ping_mode is ${C_F_BLUE}${ping_package_type}${C_F_RES}\n"
		sleep 5
		net_main_stress_type ${ping_package_ip}
	elif [ "${ping_package_type}" -eq 2 ]
	then
		# network domain name connectivity verification
		printf "Select ping_mode is ${C_F_BLUE}${ping_package_type}${C_F_RES}\n"
		sleep 5
		net_main_stress_type ${ping_package_domain}
	else
		printf "${SOURCE_PATH}/config.json \"ping_mode\" error\n"
	fi
}
