#!/bin/bash
SOURCE_PATH=/home/worker/GG31_SYSTEM
source ${SOURCE_PATH}/etc/common.sh
source ${SOURCE_PATH}/etc/function.sh
source ${SOURCE_PATH}/etc/install_deb.sh

cdu_dependency_package(){
	# Dependency package installation
	install_deb_check "csvlook" install_deb_csvkit
	install_deb_check "firefox" install_deb_firefox
	install_deb_check "gnuplot" install_deb_gnuplot
}

cdu_result_status_check(){
	# check result : command excute status
	if [ "$?" -eq 0 ]
	then
		let $1=$1+1
	else
		let $2=$2+1
	fi
}

cdu_config_para_check(){
	# cdu config parameter check
	local config_ub964=$(config_ub964.sh)
	local video0_num=$(echo "${config_ub964}" | grep -a -c video0)
	local video1_num=$(echo "${config_ub964}" | grep -a -c video1)
	if [ "${cdu_video0_num}" -ne "${video0_num}" ]
	then
		printf "${SOURCE_PATH}/config.json video0_num is ${cdu_video0_num}\n"
		printf "config_ub964.sh checked insert video0_num is ${video0_num}\n"
		printf "The both do not match\n"
		exit 1
	fi
	if [ "${cdu_video1_num}" -ne "${video1_num}" ]
	then
		printf "${SOURCE_PATH}/config.json video1_num is ${cdu_video1_num}\n"
		printf "config_ub964.sh checked insert video1_num is ${video1_num}\n"
		printf "The both do not match\n"
		exit 1
	fi
}

cdu_main_stress_master(){
	# master port cdu dump video data
	if [ "${cdu_video0_num}" -gt 0 ]
	then
		timeout 10 dump_video0.sh -n ${cdu_video0_num}
		cdu_result_status_check camdump0_m_s camdump0_m_f
	fi
	if [ "${cdu_video1_num}" -gt 0 ]
	then
		timeout 10 dump_video1.sh -n ${cdu_video1_num}
		cdu_result_status_check camdump1_m_s camdump1_m_f
	fi
}

cdu_main_stress_slave(){
	# slave port cdu dump video data
	if [ "${cdu_video0_num}" -gt 0 ]
	then
		ssh slave "timeout 10 dump_video0.sh -n ${cdu_video0_num}"
		cdu_result_status_check camdump0_s_s camdump0_s_f
	fi
	if [ "${cdu_video1_num}" -gt 0 ]
	then
		ssh slave "timeout 10 dump_video1.sh -n ${cdu_video1_num}"
		cdu_result_status_check camdump1_s_s camdump1_s_f
	fi
}

cdu_result_statistic(){
	# format result output
	printf "date,port,project,sub_project,test_num,succ_num,fail_num\n"
	printf "$(date "+%F %T"),master,cdu,video0,$test_init,$camdump0_m_s,$camdump0_m_f\n"
	printf "$(date "+%F %T"),master,cdu,video1,$test_init,$camdump1_m_s,$camdump1_m_f\n"
	printf "$(date "+%F %T"),slave,cdu,video0,$test_init,$camdump0_s_s,$camdump0_s_f\n"
	printf "$(date "+%F %T"),slave,cdu,video1,$test_init,$camdump1_s_s,$camdump1_s_f\n"
}

cdu_output_png(){
	# create cdu info png
	echo "
	set terminal png size 1280,720
	set output \"${R_P_LOG_CDU}/cdu.png\"
	set multiplot layout 2,2
	set border lc rgb \"orange\"
	set xlabel \"times\" font \",15\"
	set xrange [-2:$test_init]
	set yrange [-2:$test_init]
	set xtics textcolor rgb \"orange\"
	set ytics textcolor rgb \"orange\"
	set grid x,y lc rgb \"orange\"
	set key box reverse
	set datafile sep \",\"
	set origin 0,0.5
	set title \"CDU-Video0-Dump \(Master\)\" font \",16\"
	plot \"${R_P_LOG_CDU}/cdu_video0_master.log\" u 6 w l lw 2 lc 1 t 'Dump-S',\
	'' u 7 w l lw 2 lc 7 t 'Dump-F'
	set origin 0.5,0.5
	set title \"CDU-Video1-Dump \(Master\)\" font \",16\"
	plot \"${R_P_LOG_CDU}/cdu_video0_master.log\" u 6 w l lw 2 lc 1 t 'Dump-S',\
	'' u 7 w l lw 2 lc 7 t 'Dump-F'
	set origin 0,0
	set title \"CDU-Video0-Dump \(Slave\)\" font \",16\"
	plot \"${R_P_LOG_CDU}/cdu_video0_slave.log\" u 6 w l lw 2 lc 1 t 'Dump-S',\
	'' u 7 w l lw 2 lc 7 t 'Dump-F'
	set origin 0.5,0
	set title \"CDU-Video1-Dump \(Slave\)\" font \",16\"
	plot \"${R_P_LOG_CDU}/cdu_video0_slave.log\" u 6 w l lw 2 lc 1 t 'Dump-S',\
	'' u 7 w l lw 2 lc 7 t 'Dump-F' " |gnuplot
}

cdu_output_html(){
	# create cdu info html
	local time_s=$(awk -F "," '{print $1}' ${R_P_LOG_CDU}/cdu_video0_master.log |head -1)
	local time_e=$(awk -F "," '{print $1}' ${R_P_LOG_CDU}/cdu_video0_master.log |tail -1)
	local head_m="GG3.1 cdu status monitor (${time_s} to ${time_e})"
	local cdu_info=$(csvlook ${R_P_LOG_CDU}/cdu_template.log)
	echo "
	<!DOCTYPE html>
	<html>
		<head>
			<meta charset="utf-8">
			<title>cdu status monitor</title>
			<link rel="icon" type="image/x-icon" href="${R_P_LIB_HTML}/uisee.png">
			<link rel="stylesheet" type="text/css" href="${R_P_LIB_HTML}/html_style.css">
		</head>
		<body>
			<div>
				<hr />
				<h2>${head_m}</h2>
				<hr />
				<pre>${cdu_info}</pre>
				<hr />
			</div>
			<div>
				<hr />
				<img src="${R_P_LOG_CDU}/cdu.png">
				<hr />
			</div>
		</body>
	</html>
	" > ${R_P_LOG_CDU}/cdu_monitor.html
}

cdu_main_stress(){
	cdu_dependency_package
	cdu_config_para_check
	if [ ! -d ${R_P_LOG_CDU} ]
	then
		mkdir -p ${R_P_LOG_CDU}
	fi
	local delay_time=$(jq -r ".delay_time" ${SOURCE_PATH}/config.json)
	local cdu_cycle=$(jq -r ".para_cdu.cdu_cycle" ${SOURCE_PATH}/config.json)
	local cdu_show_image=$(jq -r ".para_cdu.cdu_image.show_interval" ${SOURCE_PATH}/config.json)
	local cdu_switch_image=$(jq -r ".para_cdu.cdu_image.show_switch" ${SOURCE_PATH}/config.json)
	local cdu_video0_num=$(jq -r ".para_cdu.cdu_video.video0_num" ${SOURCE_PATH}/config.json)
	local cdu_video1_num=$(jq -r ".para_cdu.cdu_video.video1_num" ${SOURCE_PATH}/config.json)
	local camdump0_m_s=0 camdump0_m_f=0 camdump1_m_s=0 camdump1_m_f=0
	local camdump0_s_s=0 camdump0_s_f=0 camdump1_s_s=0 camdump1_s_f=0
	local test_init cycle
	for ((test_init=1;test_init<=${cdu_cycle};test_init++))
	do
		cdu_main_stress_master
		cdu_main_stress_slave
		cdu_result_statistic > ${R_P_LOG_CDU}/cdu_template.log
		csvlook ${R_P_LOG_CDU}/cdu_template.log
		tail -4 ${R_P_LOG_CDU}/cdu_template.log |head -1 >> ${R_P_LOG_CDU}/cdu_video0_master.log
		tail -3 ${R_P_LOG_CDU}/cdu_template.log |head -1 >> ${R_P_LOG_CDU}/cdu_video1_master.log
		tail -2 ${R_P_LOG_CDU}/cdu_template.log |head -1 >> ${R_P_LOG_CDU}/cdu_video0_slave.log
		tail -1 ${R_P_LOG_CDU}/cdu_template.log >> ${R_P_LOG_CDU}/cdu_video1_slave.log
		sleep ${delay_time}
		let cycle=${test_init}%${cdu_show_image}
		if [ "${cycle}" -eq 0 ]
		then
			cdu_output_png
			cdu_output_html
			if [ "${cdu_switch_image}" -eq 1 ]
			then
				timeout 20 firefox ${R_P_LOG_CDU}/cdu_monitor.html > ${C_D_NULL} 2>&1
			fi
		fi
	done
}
