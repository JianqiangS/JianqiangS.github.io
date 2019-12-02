#!/bin/bash
SOURCE_PATH=/home/worker/GG31_SYSTEM
source ${SOURCE_PATH}/etc/common.sh
source ${SOURCE_PATH}/etc/function.sh
source ${SOURCE_PATH}/etc/install_deb.sh

temp_dependency_package(){
	# dependency package installation
	install_deb_check "csvlook" install_deb_csvkit
	install_deb_check "firefox" install_deb_firefox
	install_deb_check "gnuplot" install_deb_gnuplot
}

temp_help_info(){
	# test environment temp
	printf "Temp mode : ${C_F_GREEN}Normal${C_F_RES} / ${C_F_RED}High${C_F_RES} / ${C_F_BLUE}Low${C_F_RES}\n"
	printf "\t\"temp_mode\": 0 , normal temp , temp range 20C-85C \n"
	printf "\t\"temp_mode\": 1 , high   temp , temp range 40C-110C\n"
	printf "\t\"temp_mode\": 2 , low    temp , temp range -30C-40C\n"
}

temp_config_para_check(){
	# temp mode config verify
	local temp_mode=$(jq -r ".para_temp.temp_mode" ${SOURCE_PATH}/config.json)
	temp_help_info
	if [ "${temp_mode}" -eq 0 ]
	then
		yrange_min=20
		yrange_max=85
	elif [ "${temp_mode}" -eq 1 ]
	then 
		yrange_min=40
		yrange_max=110
	elif [ "${temp_mode}" -eq 2 ]
	then 
		yrange_min=-30
		yrange_max=40
	else
		printf "${SOURCE_PATH}/config.json \"temp_mode\" error\n"
		exit 1
	fi
	printf "Current select temp mode is ${temp_mode} , temp range is ${yrange_min}C to ${yrange_max}C\n"
	sleep 5
}

temp_result_status_check(){
	# temp status info extraction
	function_temp_status_info "${tegrastats_info}"
	local temp_status_1="${temp_bcpu},${temp_mcpu},${temp_gpu}"
	local temp_status_2="${temp_pll},${temp_tboard},${temp_thermal}"
	printf "$(date "+%F %T"),$1,temp,${test_init},${temp_status_1},${temp_status_2}\n"
}

temp_result_statistic_master(){
	# master port temp status information
	local tegrastats_info=$(sudo timeout 2 /home/worker/tegrastats)
	temp_result_status_check "master"
}

temp_result_statistic_slave(){
	# slave port temp status information
	local tegrastats_info=$(ssh slave "sudo timeout 2 /home/worker/tegrastats")
	temp_result_status_check "slave"
}

temp_result_statistic_template(){
	# temp status information
	local temp_1="T-BCPU,T-MCPU,T-GPU"
	local temp_2="T-PLL,T-Bboard,T-Thermal"
	printf "date,port,project,test_num,${temp_1},${temp_2}\n"
	temp_result_statistic_master
	temp_result_statistic_slave
}

temp_result_statistic(){
	# temp stress excute
	local delay_time=$(jq -r ".delay_time" ${SOURCE_PATH}/config.json)
	local temp_cycle=$(jq -r ".para_temp.temp_cycle" ${SOURCE_PATH}/config.json)
	local temp_show_image=$(jq -r ".para_temp.temp_image.show_interval" ${SOURCE_PATH}/config.json)
	local temp_switch_image=$(jq -r ".para_temp.temp_image.show_switch" ${SOURCE_PATH}/config.json)
	local test_init cycle
	for ((test_init=1;test_init<=${temp_cycle};test_init++))
	do
		sleep ${delay_time}
		temp_result_statistic_template > ${R_P_LOG_TEMP}/temp_template.log
		csvlook ${R_P_LOG_TEMP}/temp_template.log
		tail -2 ${R_P_LOG_TEMP}/temp_template.log |head -1 >> ${R_P_LOG_TEMP}/temp_master_statistic.log
		tail -1 ${R_P_LOG_TEMP}/temp_template.log >> ${R_P_LOG_TEMP}/temp_slave_statistic.log
		let cycle=${test_init}%${temp_show_image}
		if [ "${cycle}" -eq 0 ]
		then
			temp_output_png
			temp_output_html
			if [ "${temp_switch_image}" -eq 1 ]
			then
				timeout 20 firefox ${R_P_LOG_TEMP}/temp_monitor.html > ${C_D_NULL} 2>&1
			fi
		fi
	done
}

temp_output_png_template(){
	# output temp info png
	echo "
	set terminal png size 1280,720
	set output \"${R_P_LOG_TEMP}/temp_$1.png\"
	set border lc rgb \"orange\"
	set xlabel \"times\" font \",16\"
	set ylabel \"temp : C\" font \",16\"
	set xrange [-1:$test_init]
	set yrange [$yrange_min:$yrange_max]
	set xtics textcolor rgb \"orange\"
	set ytics textcolor rgb \"orange\"
	set grid x,y lc rgb \"orange\"
	set datafile sep ','
	set key box reverse
	plot \"${R_P_LOG_TEMP}/$2\" u 5 smooth csplines w l lw 2 lc 1 t 'Temp: BCPU',\
	'' u 6 smooth csplines w l lw 2 lc 2 t 'Temp: MCPU',\
	'' u 7 smooth csplines w l lw 2 lc 4 t 'Temp: GPU',\
	'' u 8 smooth csplines w l lw 2 lc 6 t 'Temp: PLL',\
	'' u 9 smooth csplines w l lw 2 lc 7 t 'Temp: Tboard',\
	'' u 10 smooth csplines w l lw 2 lc 8 t 'Temp: Thermal' " | gnuplot
}

temp_output_png(){
	# output master and slave png
	temp_output_png_template "master" temp_master_statistic.log
	temp_output_png_template "slave" temp_slave_statistic.log
}

temp_output_html(){
	local time_s=$(awk -F "," '{print $1}' ${R_P_LOG_TEMP}/temp_master_statistic.log |head -1)
	local time_e=$(awk -F "," '{print $1}' ${R_P_LOG_TEMP}/temp_master_statistic.log |tail -1)
	local head_m="GG3.1 master port temp status monitor (${time_s} to ${time_e})"
	local head_s="GG3.1 slave port temp status monitor (${time_s} to ${time_e})"
	local temp_info=$(csvlook ${R_P_LOG_TEMP}/temp_template.log)
	echo "
	<!DOCTYPE html>
	<html>
		<head>
			<meta charset="utf-8">
			<title>temp status monitor</title>
			<link rel="icon" type="image/x-icon" href="${R_P_LIB_HTML}/uisee.png">
			<link rel="stylesheet" type="text/css" href="${R_P_LIB_HTML}/html_style.css">
		</head>
		<body>
			<div>
				<hr />
				<h2>"GG3.1 temp status monitor"</h2>
				<hr />
				<pre>${temp_info}</pre>
				<hr />
			</div>
			<div>
				<hr />
				<h4>${head_m}</h4>
				<hr />
				<img src="${R_P_LOG_TEMP}/temp_master.png">
				<hr />
			</div>
			<div>
				<hr />
				<h4>${head_s}</h4>
				<hr />
				<img src="${R_P_LOG_TEMP}/temp_slave.png">
				<hr />
			</div>
		</body>
	</html>
	" > ${R_P_LOG_TEMP}/temp_monitor.html
}

temp_main_stress(){
	# main program
	temp_config_para_check
	temp_dependency_package
	if [ ! -d ${R_P_LOG_TEMP} ]
	then
		mkdir -p  ${R_P_LOG_TEMP}
	fi
	temp_result_statistic
}
