#!/bin/bash
SOURCE_PATH=/home/worker/GG31_SYSTEM
source ${SOURCE_PATH}/etc/common.sh
source ${SOURCE_PATH}/etc/install_deb.sh

dsi_dependency_package(){
	# dependency package installation
	install_deb_check "csvlook" install_deb_csvkit
	install_deb_check "firefox" install_deb_firefox
	install_deb_check "gnuplot" install_deb_gnuplot
}

dsi_result_statistic(){
	# dsi test result statistic
	printf "date,port,project,test_num,success_num,fail_num\n"
	printf "$(date "+%F %T"),slave,dsi,$test_init,$succ,$fail\n"
}

dsi_main_stress_slave(){
	# monitor dsi dispaly status
	local dsi_status=$(ssh slave "sudo gmsl_i2c_op r 0x48 0x03")
	printf "${dsi_status}\n" | grep -a "31" > ${C_D_NULL} 2>&1
	if [ "$?" -eq 0 ]
	then
		let succ++
	else
		let fail++
	fi
	dsi_result_statistic > ${R_P_LOG_DSI}/dsi_template.log
	csvlook ${R_P_LOG_DSI}/dsi_template.log
	tail -1 ${R_P_LOG_DSI}/dsi_template.log >> ${R_P_LOG_DSI}/dsi_statistic.log
}

dsi_output_png(){
	echo "
	set terminal png size 1080,720
	set output \"$R_P_LOG_DSI/dsi.png\"
	set border lc rgb \"orange\"
	set xlabel \"times\" font \",16\"
	set ylabel \"frequency\" font \",16\"
	set xrange [-1:$test_init]
	set yrange [-1:$test_init]
	set grid x,y lc rgb \"orange\"
	set key box reverse
	set datafile sep ','
	plot \"$R_P_LOG_DSI/dsi_statistic.log\" u 5 w l lc 1 lw 2 t \"DSI : S-Times\",\
	'' u 6 w l lc 7 lw 2 t \"DSI : F-Times\" " |gnuplot
}

dsi_output_html(){
	local time_s=$(awk -F "," '{print $1}' ${R_P_LOG_DSI}/dsi_statistic.log |head -1)
	local time_e=$(awk -F "," '{print $1}' ${R_P_LOG_DSI}/dsi_statistic.log |tail -1)
	local head_m="GG3.1 dsi status monitor (${time_s} to ${time_e})"
	local dsi_info=$(csvlook ${R_P_LOG_DSI}/dsi_template.log)
	echo "
	<!DOCTYPE html>
	<html>
		<head>
			<meta charset="utf-8">
			<title>dsi status monitor</title>
			<link rel="icon" type="image/x-icon" href="${R_P_LIB_HTML}/uisee.png">
			<link rel="stylesheet" type="text/css" href="${R_P_LIB_HTML}/html_style.css">
		</head>
		<body>
			<div>
				<hr />
				<h2>${head_m}</h2>
				<hr />
				<pre>${dsi_info}</pre>
				<hr />
			</div>
			<div>
				<hr />
				<img src="${R_P_LOG_DSI}/dsi.png">
				<hr />
			</div>
		</body>
	</html>
	" > ${R_P_LOG_DSI}/dsi_monitor.html	
}

dsi_main_stress(){
	dsi_dependency_package
	if [ ! -d "${R_P_LOG_DSI}" ]
	then
		mkdir -p ${R_P_LOG_DSI}
	fi
	local delay_time=$(jq -r ".delay_time" ${SOURCE_PATH}/config.json)
	local dsi_cycle=$(jq -r ".para_dsi.dsi_cycle" ${SOURCE_PATH}/config.json)
	local dsi_show_image=$(jq -r ".para_dsi.dsi_image.show_interval" ${SOURCE_PATH}/config.json)
	local dsi_switch_image=$(jq -r ".para_dsi.dsi_image.show_switch" ${SOURCE_PATH}/config.json)
	local succ=0 fail=0
	local test_init cycle
	for ((test_init=1;test_init<=${dsi_cycle};test_init++))
	do
		dsi_main_stress_slave
		sleep ${delay_time}
		let cycle=${test_init}%${dsi_show_image}
		if [ "${cycle}" -eq 0 ]
		then
			dsi_output_png
			dsi_output_html
			if [ "${dsi_switch_image}" -eq 1 ]
			then
				timeout 20 firefox ${R_P_LOG_DSI}/dsi_monitor.html > ${C_D_NULL} 2>&1
			fi
		fi
	done
}
