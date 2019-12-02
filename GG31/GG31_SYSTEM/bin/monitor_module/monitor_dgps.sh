#!/bin/bash
SOURCE_PATH=/home/worker/GG31_SYSTEM
source ${SOURCE_PATH}/etc/common.sh
source ${SOURCE_PATH}/etc/install_deb.sh

dgps_config_para_check(){
	# check dgps relay uos package path
	if [ ! -d "${dgps_uos_path}" ]
	then
		printf "${dgps_uos_path} not exist\n"
		printf "please check ${SOURCE_PATH}/config.json dgps_uos\n"
		exit 1
	fi
}

dgps_dependency_package(){
	# Dependency package installation
	install_deb_check "csvlook" install_deb_csvkit
	install_deb_check "firefox" install_deb_firefox
	install_deb_check "gnuplot" install_deb_gnuplot
}

dgps_main_stress_program(){
	# excute dgps location program
	cd ${dgps_uos_path}
	./bin/vstream-test -B /dev/ttyTHS1 |tee -a ${R_P_LOG_DGPS}/dgps_stress.log > ${C_D_NULL} 2>&1
}

dgps_result_statistic(){
	# output dgps statistic result 
	printf "date,port,project,test_num,total_frame,actual_frame,lost_frame\n"
	printf "$(date "+%F %T"),master,dgps,$test_init,$result_t,$result_a,$result_l\n"
}

dgps_result_status_check(){
	# check dgps status info
	result_info=$(grep -a "G" ${R_P_LOG_DGPS}/dgps_stress.log)
	result_t=$(echo "${result_info}" |wc -l)
	result_a=$(echo "${result_info}" |grep -c "$")
	let result_l=$result_t-$result_a
	dgps_result_statistic > ${R_P_LOG_DGPS}/dgps_template.log
	csvlook ${R_P_LOG_DGPS}/dgps_template.log
	tail -1 ${R_P_LOG_DGPS}/dgps_template.log >> ${R_P_LOG_DGPS}/dgps_statistic.log
}

dgps_output_png(){
	# output dgps result png
	echo "
	set terminal png size 1080,720
	set output \"$R_P_LOG_DGPS/dgps.png\"
	set border lc rgb \"orange\"
	set xlabel \"times\" font \",17\"
	set ylabel \"frame\" font \",17\"
	set xrange [-2:$test_init]
	set grid x,y lc rgb \"orange\"
	set key box reverse
	set datafile sep ','
	plot \"$R_P_LOG_DGPS/dgps_statistic.log\" u 6 w l lc 1 lw 3 t \"DGPS: Receive-A\",\
	'' u 7 w l lc 7 lw 3 t \"DGPS: Receive-L\" " |gnuplot
}

dgps_output_html(){
	# output dgps result html
	local time_s=$(awk -F "," '{print $1}' ${R_P_LOG_DGPS}/dgps_statistic.log |head -1)
	local time_e=$(awk -F "," '{print $1}' ${R_P_LOG_DGPS}/dgps_statistic.log |tail -1)
	local head_m="GG3.1 dgps status monitor (${time_s} to ${time_e})"
	local dgps_info=$(csvlook ${R_P_LOG_DGPS}/dgps_template.log)
	echo "
	<!DOCTYPE html>
	<html>
		<head>
			<meta charset="utf-8">
			<title>dgps status monitor</title>
			<link rel="icon" type="image/x-icon" href="${R_P_LIB_HTML}/uisee.png">
			<link rel="stylesheet" type="text/css" href="${R_P_LIB_HTML}/html_style.css">
		</head>
		<body>
			<div>
				<hr />
				<h2>${head_m}</h2>
				<hr />
				<pre>${dgps_info}</pre>
				<hr />
			</div>
			<div>
				<hr />
				<img src="${R_P_LOG_DGPS}/dgps.png">
				<hr />
			</div>
		</body>
	</html>
	" > ${R_P_LOG_DGPS}/dgps_monitor.html	
}

dgps_main_stress_result(){
	local delay_time=$(jq -r ".delay_time" ${SOURCE_PATH}/config.json)
	local dgps_cycle=$(jq -r ".para_dgps.dgps_cycle" ${SOURCE_PATH}/config.json)
	local dgps_show_image=$(jq -r ".para_dgps.dgps_image.show_interval" ${SOURCE_PATH}/config.json)
	local dgps_switch_image=$(jq -r ".para_dgps.dgps_image.show_switch" ${SOURCE_PATH}/config.json)
	local test_init cycle
	for ((test_init=1;test_init<=${dgps_cycle};test_init++))
	do
		sleep ${delay_time}
		dgps_result_status_check
		let cycle=${test_init}%${dgps_show_image}
		if [ "${cycle}" -eq 0 ]
		then
			dgps_output_png
			dgps_output_html
			if [ "${dgps_switch_image}" -eq 1 ]
			then
				timeout 20 firefox ${R_P_LOG_DGPS}/dgps_monitor.html > ${C_D_NULL} 2>&1
			fi
		fi
	done
	ps -ef |grep vstream-test |awk '{print $2}'|xargs sudo kill -9
}

dgps_main_stress(){
	local dgps_uos_name=$(jq -r ".para_dgps.dgps_uos" ${SOURCE_PATH}/config.json)
	local dgps_uos_path=/home/worker/${dgps_uos_name}/run
	dgps_config_para_check
	dgps_dependency_package
	if [ ! -d "${R_P_LOG_DGPS}" ]
	then
		mkdir -p ${R_P_LOG_DGPS}
	fi
	dgps_main_stress_program &
	dgps_main_stress_result
}
