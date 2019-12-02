#!/bin/bash
SOURCE_PATH=/home/worker/GG31_SYSTEM
source ${SOURCE_PATH}/etc/common.sh
source ${SOURCE_PATH}/etc/function.sh
source ${SOURCE_PATH}/etc/install_deb.sh

cpu_dependency_package(){
	# dependency package installation
	install_deb_check "csvlook" install_deb_csvkit
	install_deb_check "firefox" install_deb_firefox
	install_deb_check "gnuplot" install_deb_gnuplot
	install_deb_check "stress-ng" install_deb_stress_ng
}

cpu_main_stress_master(){
	# master port cpu N core stress
	local cpu_core_num_master=$(jq -r ".para_cpu.cpu_stress.core_num_master" ${SOURCE_PATH}/config.json)
	local board_cpu_num_master=$(lscpu |grep CPU\(s\) |head -1 |awk '{print $2}')
	if [ "${cpu_core_num_master}" -eq 0 ] || [ "${cpu_core_num_master}" -eq "${board_cpu_num_master}" ]
	then
		printf "Stress-ng starts the CPU usage ${C_F_BLUE}${board_cpu_num_master}x100%%${C_F_RES}\n"
	elif [ "${cpu_core_num_master}" -gt 0 ] && [ "${cpu_core_num_master}" -lt "${board_cpu_num_master}" ]
	then
		printf "Stress-ng starts the CPU usage ${C_F_BLUE}${cpu_core_num_master}x100%%${C_F_RES}\n"
	else
		printf "${SOURCE_PATH}/config.json para_cpu.cpu_stress.core_num_master error\n"
		printf "\tdefault cpu usage is ${C_F_BLUE}3x100%%${C_F_RES}\n"
		local cpu_core_num_master=3
	fi	
	killall stress-ng
	stress-ng --vm ${cpu_core_num_master} -t ${stress_ng_time_num}${stress_ng_time_unit}
}

cpu_main_stress_slave(){
	# slave port cpu N core stress
	local cpu_core_num_slave=$(jq -r ".para_cpu.cpu_stress.core_num_slave" ${SOURCE_PATH}/config.json)
	local board_cpu_num_slave_info=$(ssh slave "lscpu |grep CPU\(s\) |head -1")
	local board_cpu_num_slave=$(echo "${board_cpu_num_slave_info}" |awk '{print $2}')
	if [ "${cpu_core_num_slave}" -eq 0 ] || [ "${cpu_core_num_slave}" -eq "${board_cpu_num_slave}" ]
	then
		printf "Stress-ng starts the CPU usage ${C_F_BLUE}${board_cpu_num_slave}x100%%${C_F_RES}\n"
	elif [ "${cpu_core_num_slave}" -gt 0 ] && [ "${cpu_core_num_slave}" -lt "${board_cpu_num_slave}" ]
	then
		printf "Stress-ng starts the CPU usage ${C_F_BLUE}${cpu_core_num_slave}x100%%${C_F_RES}\n"
	else
		printf "${SOURCE_PATH}/config.json para_cpu.cpu_stress.core_num_slave error\n"
		printf "\tdefault cpu usage is ${C_F_BLUE}3x100%%${C_F_RES}\n"
		local cpu_core_num_slave=3
	fi	
	ssh slave "killall stress-ng"
	ssh slave "stress-ng --vm ${cpu_core_num_slave} -t ${stress_ng_time_num}${stress_ng_time_unit}"
}

cpu_main_stress_excute(){
	# cpu stress excute
	local stress_ng_time_unit=$(jq -r ".para_cpu.cpu_stress.time_unit" ${SOURCE_PATH}/config.json)
	local stress_ng_time_num=$(jq -r ".para_cpu.cpu_stress.time_num" ${SOURCE_PATH}/config.json)
	cpu_main_stress_master & 
	cpu_main_stress_slave &
}

cpu_result_status_check(){
	# cpu status info extraction
	function_cpu_status_info "${tegrastats_info}"
	function_temp_status_info "${tegrastats_info}"
	local cpu_info_012="${cpu0_rate},${cpu0_freq},${cpu1_rate},${cpu1_freq},${cpu2_rate},${cpu2_freq}"
	local cpu_info_345="${cpu3_rate},${cpu3_freq},${cpu4_rate},${cpu4_freq},${cpu5_rate},${cpu5_freq}"
	printf "$(date "+%F %T"),$1,cpu,$test_init,${cpu_info_012},${cpu_info_345},${temp_thermal}\n"
}

cpu_result_statistic_master(){
	# master port cpu status information
	local tegrastats_info=$(sudo timeout 2 /home/worker/tegrastats)
	cpu_result_status_check master
}

cpu_result_statistic_slave(){
	# slave port cpu status information
	local tegrastats_info=$(ssh slave "sudo timeout 2 /home/worker/tegrastats")
	cpu_result_status_check slave
}

cpu_result_statistic_template(){
	# cpu status information
	local cpu_012="CPU0_R,CPU0_F,CPU1_R,CPU1_F,CPU2_R,CPU2_F"
	local cpu_345="CPU3_R,CPU3_F,CPU4_R,CPU4_F,CPU5_R,CPU5_F"
	printf "date,port,project,test_num,${cpu_012},${cpu_345},temp_thermal\n"
	cpu_result_statistic_master
	cpu_result_statistic_slave
}

cpu_result_statistic(){
	# cpu stress excute
	cpu_main_stress_excute
	local cpu_cycle=$(jq -r ".para_cpu.cpu_cycle" ${SOURCE_PATH}/config.json)
	local cpu_show_image=$(jq -r ".para_cpu.cpu_image.show_interval" ${SOURCE_PATH}/config.json)
	local cpu_switch_image=$(jq -r ".para_cpu.cpu_image.show_switch" ${SOURCE_PATH}/config.json)
	local delay_time=$(jq -r ".delay_time" ${SOURCE_PATH}/config.json)
	local test_init cycle
	for ((test_init=1;test_init<=${cpu_cycle};test_init++))
	do
		sleep ${delay_time}
		cpu_result_statistic_template > ${R_P_LOG_CPU}/cpu_template.log
		csvlook ${R_P_LOG_CPU}/cpu_template.log
		tail -2 ${R_P_LOG_CPU}/cpu_template.log |head -1 >> ${R_P_LOG_CPU}/cpu_master_statistic.log
		tail -1 ${R_P_LOG_CPU}/cpu_template.log >> ${R_P_LOG_CPU}/cpu_slave_statistic.log
		let cycle=${test_init}%${cpu_show_image}
		if [ "${cycle}" -eq 0 ]
		then
			cpu_output_png
			cpu_output_html
			if [ "${cpu_switch_image}" -eq 1 ]
			then	
				timeout 20 firefox ${R_P_LOG_CPU}/cpu_monitor.html > ${C_D_NULL} 2>&1
			fi
		fi
	done
}

cpu_output_png_template(){
	# output cpu rate and freq info with png mode
	echo "
	set terminal png size 1280,720
	set output \"${R_P_LOG_CPU}/cpu_$1.png\"
	set multiplot layout 2,3
	set border lc rgb \"orange\"
	set xlabel \"times\" font \",15\"
	set xrange [-2:$test_init]
	set xtics textcolor rgb \"orange\"
	set yrange [-200:2200]
	set ytics 200 textcolor rgb \"orange\"
	set grid x,y lc rgb \"orange\"
	set datafile sep ','

	set origin 0,0.5
	set title \"CPU0-Rate-Freq \($1\)\" font \",16\"
	set ylabel \"cpu0-f-r-t\" font \",15\"
	set key box reverse spacing 0.8
	plot \"${R_P_LOG_CPU}/$2\" u 5 smooth csplines w l lw 2 lc 1 t 'CPU0: R',\
	'' u 6 smooth csplines w l lw 2 lc 2 t 'CPU0: F',\
	'' u 17 smooth csplines w l lw 2 lc 7 t 'CPU0: T'

	set origin 0.335,0.5
	set title \"CPU1-Rate-Freq \($1\)\" font \",16\"
	set ylabel \"cpu1-f-r-t\" font \",15\"
	set key box reverse
	plot \"${R_P_LOG_CPU}/$2\" u 7 smooth csplines w l lw 2 lc 1 t 'CPU1: R',\
	'' u 8 smooth csplines w l lw 2 lc 2 t 'CPU1: F',\
	'' u 17 smooth csplines w l lw 2 lc 7 t 'CPU1: T'

	set origin 0.67,0.5
	set title \"CPU2-Rate-Freq \($1\)\" font \",16\"
	set ylabel \"cpu2-f-r-t\" font \",15\"
	set key box reverse
	plot \"${R_P_LOG_CPU}/$2\" u 9 smooth csplines w l lw 2 lc 1 t 'CPU2: R',\
	'' u 10 smooth csplines w l lw 2 lc 2 t 'CPU2: F',\
	'' u 17 smooth csplines w l lw 2 lc 7 t 'CPU3: T'

	set origin 0,0
	set title \"CPU3-Rate-Freq \($1\)\" font \",16\"
	set ylabel \"cpu3-f-r-t\" font \",15\"
	set key box reverse
	plot \"${R_P_LOG_CPU}/$2\" u 11 smooth csplines w l lw 2 lc 1 t 'CPU3: R',\
	'' u 12 smooth csplines w l lw 2 lc 2 t 'CPU3: F',\
	'' u 17 smooth csplines w l lw 2 lc 7 t 'CPU3: T'

	set origin 0.335,0
	set title \"CPU4-Rate-Freq \($1\)\" font \",16\"
	set ylabel \"cpu4-f-r-t\" font \",15\"
	set key box reverse
	plot \"${R_P_LOG_CPU}/$2\" u 13 smooth csplines w l lw 2 lc 1 t 'CPU4: R',\
	'' u 14 smooth csplines w l lw 2 lc 2 t 'CPU4: F',\
	'' u 17 smooth csplines w l lw 2 lc 7 t 'CPU4: T'

	set origin 0.67,0
	set title \"CPU5-Rate-Freq \($1\)\" font \",16\"
	set ylabel \"cpu5-f-r-t\" font \",15\"
	set key box reverse
	plot \"${R_P_LOG_CPU}/$2\" u 15 smooth csplines w l lw 2 lc 1 t 'CPU5: R',\
	'' u 16 smooth csplines w l lw 2 lc 2 t 'CPU5: F',\
	'' u 17 smooth csplines w l lw 2 lc 7 t 'CPU5: T'" | gnuplot
}

cpu_output_png(){
	# output master and slave png
	cpu_output_png_template "master" cpu_master_statistic.log
	cpu_output_png_template "slave" cpu_slave_statistic.log
}

cpu_output_html(){
	# output master and slave html
	local time_s=$(awk -F "," '{print $1}' ${R_P_LOG_CPU}/cpu_master_statistic.log |head -1)
	local time_e=$(awk -F "," '{print $1}' ${R_P_LOG_CPU}/cpu_master_statistic.log |tail -1)
	local head_m="GG3.1 master port cpu status monitor (${time_s} to ${time_e})"
	local head_s="GG3.1 slave port cpu status monitor (${time_s} to ${time_e})"
	local cpu_info=$(csvlook ${R_P_LOG_CPU}/cpu_template.log)
	echo "
	<!DOCTYPE html>
	<html>
		<head>
			<meta charset="utf-8">
			<title>cpu status monitor</title>
			<link rel="icon" type="image/x-icon" href="${R_P_LIB_HTML}/uisee.png">
			<link rel="stylesheet" type="text/css" href="${R_P_LIB_HTML}/html_style.css">
		</head>
		<body>
			<div>
				<hr />
				<h2>"GG3.1 cpu status monitor"</h2>
				<hr />
				<pre>${cpu_info}</pre>
				<hr />
			</div>
			<div>
				<hr />
				<h4>${head_m}</h4>
				<hr />
				<img src="${R_P_LOG_CPU}/cpu_master.png">
				<hr />
			</div>
			<div>
				<hr />
				<h4>${head_s}</h4>
				<hr />
				<img src="${R_P_LOG_CPU}/cpu_slave.png">
				<hr />
			</div>
		</body>
	</html>
	" > ${R_P_LOG_CPU}/cpu_monitor.html
}

cpu_main_stress(){
	# main program
	cpu_dependency_package
	if [ ! -d ${R_P_LOG_CPU} ]
	then
		mkdir -p  ${R_P_LOG_CPU}
	fi
	cpu_result_statistic
}
