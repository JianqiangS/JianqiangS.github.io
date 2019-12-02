#!/bin/bash
SOURCE_PATH=/home/worker/GG31_SYSTEM
source ${SOURCE_PATH}/etc/common.sh
source ${SOURCE_PATH}/etc/install_deb.sh

iperf_dependency_package(){
	# dependency package installation
	install_deb_check "csvlook" install_deb_csvkit
	install_deb_check "firefox" install_deb_firefox
	install_deb_check "gnuplot" install_deb_gnuplot
}

iperf_help_info(){
	# iperf config help info
	printf "Iperf_mode [1/2]\n"
	printf "\t\"iperf_mode\": 1 , iperf server (master)\n"
	printf "\t\"iperf_mode\": 2 , iperf server (slave)\n"
}

iperf_main_stress_master_server(){
	# master port as iperf server
	sudo killall iperf
	iperf -u -s |tee -a ${R_P_LOG_IPERF}/iperf_server.log
}

iperf_main_stress_slave_server(){
	# slave port as iperf server
	ssh ${P_I_SLAVE} "sudo killall iperf"
	ssh ${P_I_SLAVE} "iperf -u -s" |tee -a ${R_P_LOG_IPERF}/iperf_server.log
}

iperf_result_statistic(){
	# iperf excute log detection
	local iperf_run_succ=0
	local iperf_run_fail=0
	local iperf_info=$(grep -a sec ${R_P_LOG_IPERF}/iperf_server.log |awk -F "(" '{print $2}')
	local iperf_result=$(echo "${iperf_info}" |awk -F "%" '{print $1}'|awk -F "." '{print $1}')
	for per_result in $(echo "${iperf_result}")
	do
		if [ "${per_result}" -ge 1 ]
		then
			let iperf_run_fail++
		else
			let iperf_run_succ++
		fi
	done
	let iperf_run_time=${iperf_run_succ}+${iperf_run_fail}
	{
	printf "date,port,project,test_num,success_num,fail_num\n"
	printf "$(date "+%F %T"),${iperf_server_port},iperf,${iperf_run_time},${iperf_run_succ},${iperf_run_fail}\n" 
	} > ${R_P_LOG_IPERF}/iperf_template.log
	csvlook ${R_P_LOG_IPERF}/iperf_template.log
	tail -1 ${R_P_LOG_IPERF}/iperf_template.log >> ${R_P_LOG_IPERF}/iperf_statistic.log
}

iperf_output_png(){
	echo "
	set terminal png size 1080,720
	set output \"$R_P_LOG_IPERF/iperf.png\"
	set border lc rgb \"orange\"
	set xlabel \"times\" font \",16\"
	set ylabel \"frequency\" font \",16\"
	set xrange [-2:$iperf_run_time]
	set yrange [-2:$iperf_run_time]
	set grid x,y lc rgb \"orange\"
	set key box reverse
	set datafile sep ','
	plot \"${R_P_LOG_IPERF}/iperf_statistic.log\" u 5 w l lc 1 lw 2 t \"IPERF: <1%\",\
	'' u 6 w l lc 7 lw 2 t \"IPERF: >=1%\" " |gnuplot
}

iperf_output_html(){
	local time_s=$(awk -F "," '{print $1}' ${R_P_LOG_IPERF}/iperf_statistic.log |head -1)
	local time_e=$(awk -F "," '{print $1}' ${R_P_LOG_IPERF}/iperf_statistic.log |tail -1)
	local head_m="GG3.1 iperf status monitor (${time_s} to ${time_e})"
	local iperf_info=$(csvlook ${R_P_LOG_IPERF}/iperf_template.log)
	echo "
	<!DOCTYPE html>
	<html>
		<head>
			<meta charset="utf-8">
			<title>iperf status monitor</title>
			<link rel="icon" type="image/x-icon" href="${R_P_LIB_HTML}/uisee.png">
			<link rel="stylesheet" type="text/css" href="${R_P_LIB_HTML}/html_style.css">
		</head>
		<body>
			<div>
				<hr />
				<h2>${head_m}</h2>
				<hr />
				<pre>${iperf_info}</pre>
				<hr />
			</div>
			<div>
				<hr />
				<img src="${R_P_LOG_IPERF}/iperf.png">
				<hr />
			</div>
		</body>
	</html>
	" > ${R_P_LOG_IPERF}/iperf_monitor.html
}

iperf_main_stress_result(){
	local iperf_show_image=$(jq -r ".para_iperf.iperf_image.show_interval" ${SOURCE_PATH}/config.json)
	local iperf_switch_image=$(jq -r ".para_iperf.iperf_image.show_switch" ${SOURCE_PATH}/config.json)
	while true
	do
		iperf_result_statistic
		local cycle
		let cycle=${iperf_run_time}%${iperf_show_image}
		if [ "${cycle}" -eq 0 ]
		then
			iperf_output_png
			iperf_output_html
			if [ "${iperf_switch_image}" -eq 1 ]
			then
				timeout 20 firefox ${R_P_LOG_IPERF}/iperf_monitor.html > ${C_D_NULL} 2>&1
			fi
		fi
		sleep ${delay_time} 
	done
}

iperf_main_stress_master(){
	# master port iperf excute
	iperf_main_stress_master_server &
	sleep ${delay_time} 
	iperf_main_stress_result
}

iperf_main_stress_slave(){
	# slave port iperf excute
	iperf_main_stress_slave_server &
	sleep ${delay_time}
	iperf_main_stress_result
}

iperf_main_stress(){
	# iperf stress test
	iperf_dependency_package
	if [ ! -d ${R_P_LOG_IPERF} ]
	then
		mkdir -p ${R_P_LOG_IPERF}
	fi
	local iperf_mode=$(jq -r ".para_iperf.iperf_mode" ${SOURCE_PATH}/config.json)
	local delay_time=$(jq -r ".delay_time" ${SOURCE_PATH}/config.json)
	iperf_help_info
	if [ "${iperf_mode}" -eq 1 ]
	then
		# master port as iperf server
		printf "Select iperf_mode ${C_F_BLUE}${iperf_mode}${C_F_RES}\n"
		sleep 5
		iperf_server_port="master"
		iperf_main_stress_master
	elif [ "${iperf_mode}" -eq 2 ]
	then
		# slave port as iperf server
		printf "Select iperf_mode ${C_F_BLUE}${iperf_mode}${C_F_RES}\n"
		sleep 5
		iperf_server_port="slave"
		iperf_main_stress_slave
	else
		printf "${SOURCE_PATH}/config.json \"iperf_mode\" error\n"
		exit 1
	fi
}
