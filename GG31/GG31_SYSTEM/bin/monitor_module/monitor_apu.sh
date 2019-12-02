#!/bin/bash
SOURCE_PATH=/home/worker/GG31_SYSTEM
source ${SOURCE_PATH}/etc/common.sh
source ${SOURCE_PATH}/etc/function.sh
source ${SOURCE_PATH}/etc/install_deb.sh

apu_dependency_package(){
	# Dependency package installation
	install_deb_check "csvlook" install_deb_csvkit
	install_deb_check "firefox" install_deb_firefox
	install_deb_check "gnuplot" install_deb_gnuplot
}

apu_help_info_file(){
	# Apu upgrade mode help information
	printf "Apu_file_mode [1/2]\n"
	printf "\t1 : mean apu upgrades e100 file\n"
	printf "\t2 : mean apu upgrades e100w file\n"
}

apu_help_info_mode(){
	# Apu upgrade mode help information
	printf "Apu_upgrade_mode [1/2]\n"
	printf "\t1 : mean apu upgrades normally\n"
	printf "\t2 : mean apu upgrades abnormal\n"
}

apu_help_info_time(){
	# Apu upgrade failure time help information
	printf "Apu_upgrade_time_mode [1/2]\n"
	printf "\t1 : mean apu millsecond ($apu_mil_time) lever upgrades\n"
	printf "\t2 : mean apu second ($apu_sec_time) lever upgrades\n"
}

apu_result_statistic_abmode(){
	# A/B mode result extraction
	count_apu_a=$(grep -a -c "$APU_UPGRADE_FILE_A" $1)
	count_apu_b=$(grep -a -c "$APU_UPGRADE_FILE_B" $1)
}

apu_result_statistic_normal(){
	# Apu normal upgrade statistci log output
	printf "date,port,project,sub_project,test_num,success/srec_a,num,fail/srec_b,num\n"
	printf "$(date "+%F %T"),master,apu,upgrade_normal,$test_init,success,$success,fail,$fail\n"
	apu_result_statistic_abmode ${R_P_LOG_APU_N}/apu_test.log
	printf "$(date "+%F %T"),master,apu,upgrade_normal,$test_init,srec_a,$count_apu_a,srec_b,$count_apu_b\n"
}

apu_main_stress_program(){
	# Apu normal upgrade running main program
	./updata_apu.sh /dev/ttyTHS2 ${F_P_APU_TARGET}/${APU_UPGRADE_FILE}
	if [ "$?" -eq 0 ]
	then
		let success++
	else
		let fail++
	fi
}

apu_output_png_normal(){
	local yrange_a=0 yrange_b=0 yrange_ab=0
	local yrange_a=$(awk -F "," '{print $7}' ${R_P_LOG_APU_N}/apu_ab_statistic.log |tail -1)
	local yrange_b=$(awk -F "," '{print $9}' ${R_P_LOG_APU_N}/apu_ab_statistic.log |tail -1)
	if [ "${yrange_a}" -lt "${yrange_b}" ]
	then
		yrange_ab=${yrange_b}
	else
		yrange_ab=${yrange_a}
	fi
	let yrange_ab=$yrange_ab+10
	echo "
	set terminal png size 1280,720
	set output \"${R_P_LOG_APU_N}/apu_normal.png\"
	set multiplot layout 1,2
	set border lc rgb \"orange\"
	set grid x,y lc rgb \"orange\"
	set key box reverse
	set xlabel \"times\" font \",16\"
	set ylabel \"frequency\" font \",16\"
	set datafile sep ','
	set origin 0,0
	set title \"APU-Normal-Upgrade\" font \",18\"
	set xrange [-2:$test_init]
	set yrange [-2:$test_init]
	plot \"${R_P_LOG_APU_N}/apu_sf_statistic.log\" u 7 w l lc 1 lw 2 t 'Normal-S',\
	'' u 9 w l lc 7 lw 2 t 'Normal-F'
	set origin 0.5,0
	set title \"APU-Normal-AB\" font \",18\"
	set xrange [-2:$test_init]
	set yrange [-2:$yrange_ab]
	plot \"${R_P_LOG_APU_N}/apu_ab_statistic.log\" u 7 w l lc 1 lw 2 t 'Normal-A',\
	'' u 9 w l lc 2 lw 2 t 'Normal-B' " |gnuplot
}

apu_output_html_normal(){
	local time_s=$(awk -F "," '{print $1}' ${R_P_LOG_APU_N}/apu_sf_statistic.log |head -1)
	local time_e=$(awk -F "," '{print $1}' ${R_P_LOG_APU_N}/apu_ab_statistic.log |tail -1)
	local head_m="GG3.1 apu upgrade (normal) status monitor (${time_s} to ${time_e})"
	local apu_info=$(csvlook ${R_P_LOG_APU_N}/apu_template.log)
	echo "
	<!DOCTYPE html>
	<html>
		<head>
			<meta charset="utf-8">
			<title>apu status monitor</title>
			<link rel="icon" type="image/x-icon" href="${R_P_LIB_HTML}/uisee.png">
			<link rel="stylesheet" type="text/css" href="${R_P_LIB_HTML}/html_style.css">
		</head>
		<body>
			<div>
				<hr />
				<h2>${head_m}</h2>
				<hr />
				<pre style>${apu_info}</pre>
				<hr />
			</div>
			<div>
				<hr />
				<img src="${R_P_LOG_APU_N}/apu_normal.png">
				<hr />
			</div>
		</body>
	</html>
	" > ${R_P_LOG_APU_N}/apu_monitor.html
}

apu_main_stress_normal(){
	# Apu normal upgrade main program
	cd ${F_P_APU_HOST}
	local success=0 fail=0
	local test_init cycle
	for ((test_init=1;test_init<=${apu_cycle};test_init++))
	do
		apu_main_stress_program
		apu_result_statistic_normal > ${R_P_LOG_APU_N}/apu_template.log
		csvlook ${R_P_LOG_APU_N}/apu_template.log
		tail -2 ${R_P_LOG_APU_N}/apu_template.log |head -1 >> ${R_P_LOG_APU_N}/apu_sf_statistic.log
		tail -1 ${R_P_LOG_APU_N}/apu_template.log >> ${R_P_LOG_APU_N}/apu_ab_statistic.log
		sleep ${delay_time}
		let cycle=${test_init}%${apu_show_image}
		if [ "${cycle}" -eq 0 ]
		then
			apu_output_png_normal
			apu_output_html_normal
			if [ "${apu_switch_image}" -eq 1 ]
			then
				timeout 20 firefox ${R_P_LOG_APU_N}/apu_monitor.html > ${C_D_NULL} 2>&1
			fi
		fi
	done
}

apu_result_statistic_abnormal(){
	# Apu continuous failed upgrade log output
	printf "date,port,project,sub_project,fail_time,first(i),second(j),success/srec_a,num,fail/srec_b,num\n"
	printf "$(date "+%F %T"),master,apu,continu_failed,$k,$i,$j,success,$success,fail,$fail\n"
	apu_result_statistic_abmode ${R_P_LOG_APU_A}/apu_test.log
	printf "$(date "+%F %T"),master,apu,continu_failed,$k,$i,$j,srec_a,$count_apu_a,srec_b,$count_apu_b\n"
}

apu_output_png_abnormal(){
	# Output apu abnormal upgrade png
	local yrange_a=0 yrange_b=0 yrange_ab=0
	local yrange_a=$(awk -F "," '{print $9}' ${R_P_LOG_APU_A}/apu_ab_statistic.log |tail -1)
	local yrange_b=$(awk -F "," '{print $11}' ${R_P_LOG_APU_A}/apu_ab_statistic.log |tail -1)
	if [ "${yrange_a}" -lt "${yrange_b}" ]
	then
		yrange_ab=${yrange_b}
	else
		yrange_ab=${yrange_a}
	fi
	let yrange_ab=$yrange_ab+10
	echo "
	set terminal png size 1280,720
	set output \"${R_P_LOG_APU_A}/apu_abnormal.png\"
	set multiplot layout 1,2
	set border lc rgb \"orange\"
	set grid x,y lc rgb \"orange\"
	set key box reverse
	set xlabel \"times\" font \",16\"
	set ylabel \"frequency\" font \",16\"
	set datafile sep ','
	set origin 0,0
	set title \"APU-Abnormal-Upgrade\" font \",18\"
	set xrange [-2:$test_init]
	set yrange [-2:$test_init]
	plot \"${R_P_LOG_APU_A}/apu_sf_statistic.log\" u 9 w l lc 1 lw 2 t 'Abnormal-S',\
	'' u 11 w l lc 7 lw 2 t 'Abnormal-F'
	set origin 0.5,0
	set title \"APU-Abnormal-AB\" font \",18\"
	set xrange [-2:$test_init]
	set yrange [-2:$yrange_ab]
	plot \"${R_P_LOG_APU_A}/apu_ab_statistic.log\" u 9 w l lc 1 lw 2 t 'Abnormal-A',\
	'' u 11 w l lc 2 lw 2 t 'Abnormal-B' " |gnuplot
}

apu_output_html_abnormal(){
	# Output apu abnormal upgrade html
	local time_s=$(awk -F "," '{print $1}' ${R_P_LOG_APU_A}/apu_sf_statistic.log |head -1)
	local time_e=$(awk -F "," '{print $1}' ${R_P_LOG_APU_A}/apu_ab_statistic.log |tail -1)
	local head_m="GG3.1 apu upgrade (abnormal) status monitor (${time_s} to ${time_e})"
	local apu_info=$(csvlook ${R_P_LOG_APU_A}/apu_template.log)
	echo "
	<!DOCTYPE html>
	<html>
		<head>
			<meta charset="utf-8">
			<title>apu status monitor</title>
			<link rel="icon" type="image/x-icon" href="${R_P_LIB_HTML}/uisee.png">
			<link rel="stylesheet" type="text/css" href="${R_P_LIB_HTML}/html_style.css">
		</head>
		<body>
			<div>
				<hr />
				<h2>${head_m}</h2>
				<hr />
				<pre>${apu_info}</pre>
				<hr />
			</div>
			<div>
				<hr />
				<img src="${R_P_LOG_APU_A}/apu_abnormal.png">
				<hr />
			</div>
		</body>
	</html>
	" > ${R_P_LOG_APU_A}/apu_monitor.html	
}

apu_main_stress_abnormal(){
	# Apu normal status fail upgrade first cycle
	local apu_fail_times=$(jq -r ".para_apu.apu_abnormal.fail_times" ${SOURCE_PATH}/config.json)
	for ((j=1;j<=${apu_fail_times};j++))
	do
		apu_main_stress_program &
		sleep $k
		ps -ef |grep -v grep |grep updata_apu |awk '{print $2}' |xargs sudo kill -9
		ps -ef |grep -v grep |grep BootCommander |awk '{print $2}' |xargs sudo kill -9
		function_progress_bar 1
		apu_result_statistic_abnormal > ${R_P_LOG_APU_A}/apu_template.log
		csvlook ${R_P_LOG_APU_A}/apu_template.log
		tail -2 ${R_P_LOG_APU_A}/apu_template.log |head -1 >> ${R_P_LOG_APU_A}/apu_sf_statistic.log
		tail -1 ${R_P_LOG_APU_A}/apu_template.log >> ${R_P_LOG_APU_A}/apu_ab_statistic.log
	done
	# continuous upgrade 2 times
	apu_main_stress_program
	apu_main_stress_program
	apu_result_statistic_abnormal > ${R_P_LOG_APU_A}/apu_template.log
	csvlook ${R_P_LOG_APU_A}/apu_template.log
	tail -2 ${R_P_LOG_APU_A}/apu_template.log |head -1 >> ${R_P_LOG_APU_A}/apu_sf_statistic.log
	tail -1 ${R_P_LOG_APU_A}/apu_template.log >> ${R_P_LOG_APU_A}/apu_ab_statistic.log
}

apu_main_stress_abnormal_mill(){
	# Apu upgrade continue fail in per millisecond
	local success=0 fail=0
	cd ${F_P_APU_HOST}
	for k in $(echo "${apu_mil_time}")
	do
		for ((i=1;i<=${apu_cycle};i++))
		do
			apu_main_stress_abnormal
			apu_output_png_abnormal
			apu_output_html_abnormal
			if [ "${apu_switch_image}" -eq 1 ]
			then
				timeout 20 firefox ${R_P_LOG_APU_A}/apu_monitor.html > ${C_D_NULL} 2>&1
			fi
		done
	done
}

apu_main_stress_abnormal_sec(){
	# Apu upgrade continue fail in per second
	local success=0 fail=0
	cd ${F_P_APU_HOST}
	for k in $(echo "${apu_sec_time}")
	do
		for ((i=1;i<=${apu_cycle};i++))
		do
			apu_main_stress_abnormal
			apu_output_png_abnormal
			if [ "${apu_switch_image}" -eq 1 ]
			then
				apu_output_html_abnormal
			fi
		done
	done
}

apu_main_stress(){
	# Program main entrance
	apu_dependency_package
	local apu_file_mode=$(jq -r ".para_apu.apu_file_mode" ${SOURCE_PATH}/config.json)
	apu_help_info_file
	if [ "${apu_file_mode}" -eq 1 ]
	then
		APU_UPGRADE_FILE=${F_N_APU_E100}
		APU_UPGRADE_FILE_A=${F_N_APU_SRECA_E100}
		APU_UPGRADE_FILE_B=${F_N_APU_SRECB_E100}
	elif [ "${apu_file_mode}" -eq 2 ]
	then
		APU_UPGRADE_FILE=${F_N_APU_E100W}
		APU_UPGRADE_FILE_A=${F_N_APU_SRECA_E100W}
		APU_UPGRADE_FILE_B=${F_N_APU_SRECB_E100W}
	else
		printf "please check $SOURCE_PATH/config.json apu_file_mode\n"
		exit 1
	fi
	printf "Select upgrade apu file is ${C_F_BLUE}${APU_UPGRADE_FILE}${C_F_RES}\n"

	local delay_time=$(jq -r ".delay_time" ${SOURCE_PATH}/config.json)
	local apu_cycle=$(jq -r ".para_apu.apu_cycle" ${SOURCE_PATH}/config.json)
	local apu_show_image=$(jq -r ".para_apu.apu_image.show_interval" ${SOURCE_PATH}/config.json)
	local apu_switch_image=$(jq -r ".para_apu.apu_image.show_switch" ${SOURCE_PATH}/config.json)
	local apu_upgrade_mode=$(jq -r ".para_apu.apu_upgrade_mode" ${SOURCE_PATH}/config.json)
	apu_help_info_mode
	if [ "${apu_upgrade_mode}" -eq 1 ]
	then
		if [ ! -d "${R_P_LOG_APU_N}" ]
		then
			mkdir -p ${R_P_LOG_APU_N}
		fi
		printf "Select upgrade apu mode is ${C_F_BLUE}${apu_upgrade_mode}${C_F_RES}\n"
		sleep 5
		apu_main_stress_normal |tee -a ${R_P_LOG_APU_N}/apu_test.log
	elif [ "${apu_upgrade_mode}" -eq 2 ]
	then
		if [ ! -d "${R_P_LOG_APU_A}" ]
		then
			mkdir -p ${R_P_LOG_APU_A}
		fi
		printf "Select upgrade apu mode is ${C_F_BLUE}${apu_upgrade_mode}${C_F_RES}\n"
		local apu_time_mode=$(jq -r ".para_apu.apu_abnormal.time_mode" ${SOURCE_PATH}/config.json)
		local apu_sec_time=$(jq -r ".para_apu.apu_abnormal.sec_time" ${SOURCE_PATH}/config.json |sed 's/,/ /g')
		local apu_mil_time=$(jq -r ".para_apu.apu_abnormal.mil_time" ${SOURCE_PATH}/config.json |sed 's/,/ /g')
		apu_help_info_time
		if [ "${apu_time_mode}" -eq 1 ]
		then
			printf "Select upgrade apu time mode is ${C_F_BLUE}${apu_time_mode}${C_F_RES}\n"
			sleep 5
			apu_main_stress_abnormal_sec |tee -a ${R_P_LOG_APU_A}/apu_test.log
		elif [ "${apu_time_mode}" -eq 2 ]
		then
			printf "Select upgrade apu time mode is ${C_F_BLUE}${apu_time_mode}${C_F_RES}\n"
			sleep 5
			apu_main_stress_abnormal_mill |tee -a ${R_P_LOG_APU_A}/apu_test.log
		else
			printf "please check $SOURCE_PATH/config.json time_mode\n"
			exit 2
		fi
	else
		printf "please check $SOURCE_PATH/config.json apu_upgrade_mode\n"
		exit 3
	fi
}
