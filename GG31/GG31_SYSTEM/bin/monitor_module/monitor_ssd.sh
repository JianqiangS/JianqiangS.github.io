#!/bin/bash
SOURCE_PATH=/home/worker/GG31_SYSTEM
source ${SOURCE_PATH}/etc/common.sh
source ${SOURCE_PATH}/etc/function.sh
source ${SOURCE_PATH}/etc/install_deb.sh

ssd_config_para_check(){
	# ssd type and ssd mount path detection
	if [ -b "${ssd_type}" ]
	then
		mounted_path=$(df -h |grep "${SSD_TYPE}" |awk '{print $6}')
		if [ "${mounted_path}" != "${ssd_mount_path}" ]
		then
			printf "${SOURCE_PATH}/config.json \"para_ssd.ssd_mounted\" error or not exist\n"
			exit 1
		fi
	else
		printf "${SOURCE_PATH}/config.json \"para_ssd.ssd_type\" error or not exist\n"
		exit 1
	fi
}

ssd_dependency_package(){
	# dependency package installation
	install_deb_check "csvlook" install_deb_csvkit
	install_deb_check "firefox" install_deb_firefox
	install_deb_check "gnuplot" install_deb_gnuplot
	install_deb_check "hdparm" install_deb_hdparm
	install_deb_check "stress-ng" install_deb_stress_ng
}

ssd_cpu_stress(){
	# cpu N core stress
	local ssd_cpu_num=$(jq -r ".para_ssd.ssd_cpu.core_num" ${SOURCE_PATH}/config.json)
	local ssd_cpu_time_num=$(jq -r ".para_ssd.ssd_cpu.time_num" ${SOURCE_PATH}/config.json)
	local ssd_cpu_time_unit=$(jq -r ".para_ssd.ssd_cpu.time_unit" ${SOURCE_PATH}/config.json)
	killall stress-ng
	stress-ng -c ${ssd_cpu_num} -t ${ssd_cpu_time_num}${ssd_cpu_time_unit}
}

ssd_cpu_temp_check(){
	local tegrastats_info=$(sudo timeout 2 /home/worker/tegrastats)
	function_cpu_status_info "$tegrastats_info"
	function_temp_status_info "$tegrastats_info"
}

ssd_main_stress_program_write(){
	# ssd write function verification
	local ssd_dd_bs=$(jq -r ".para_ssd.ssd_dd.dd_bs" ${SOURCE_PATH}/config.json)
	local ssd_dd_count=$(jq -r ".para_ssd.ssd_dd.dd_count" ${SOURCE_PATH}/config.json)
	dd if=${C_D_ZERO} of=${ssd_mount_path}/dd_write.log bs=${ssd_dd_bs} count=${ssd_dd_count} > ${R_P_LOG_SSD}/ssd_test.log 2>&1
}

ssd_result_statistic_write(){
	# ssd write function log detection
	local ssd_write=$(tail -1 ${R_P_LOG_SSD}/ssd_test.log)
	{
	printf "date,ssd_type,project,sub_project,input_size,output_size,run_time,trans_speed,temp_thermal,cpu_rate\n"
	printf "$(date "+%F %T"),${SSD_TYPE},ssd,write,${ssd_write},${temp_thermal},${cpu_all_rate}\n" 
	} > ${R_P_LOG_SSD}/ssd_template.log
	csvlook ${R_P_LOG_SSD}/ssd_template.log
	tail -1 ${R_P_LOG_SSD}/ssd_template.log >> ${R_P_LOG_SSD}/ssd_write_statistic.log
}

ssd_main_stress_write(){
	# ssd write function excute
	ssd_main_stress_program_write
	ssd_result_statistic_write
}

ssd_main_stress_program_read(){
	# ssd read function verification
	sudo hdparm -Tt ${ssd_type} > ${R_P_LOG_SSD}/ssd_test.log 2>&1
}

ssd_result_statistic_read(){
	# ssd read function log detection
	local ssd_read_cached=$(grep -i cached ${R_P_LOG_SSD}/ssd_test.log |awk -F "=" '{print $2}')
	local ssd_read_buffer=$(grep -i buffer ${R_P_LOG_SSD}/ssd_test.log |awk -F "=" '{print $2}')
	{
	printf "date,ssd_type,project,sub_project,cached_speed,buffer_speed,temp_thermal,cpu_rate\n"
	printf "$(date "+%F %T"),${SSD_TYPE},ssd,read,${ssd_read_cached},${ssd_read_buffer},${temp_thermal},${cpu_all_rate}\n" 
	} > ${R_P_LOG_SSD}/ssd_template.log
	csvlook ${R_P_LOG_SSD}/ssd_template.log
	tail -1 ${R_P_LOG_SSD}/ssd_template.log >> ${R_P_LOG_SSD}/ssd_read_statistic.log
}

ssd_main_stress_read(){
	# ssd read function excute
	ssd_main_stress_program_read
	ssd_result_statistic_read
}

ssd_main_stress_template(){
	# ssd function stress excution
	local ssd_cycle=$(jq -r ".para_ssd.ssd_cycle" ${SOURCE_PATH}/config.json)
	local ssd_show_image=$(jq -r ".para_ssd.ssd_image.show_interval" ${SOURCE_PATH}/config.json)
	local ssd_switch_image=$(jq -r ".para_ssd.ssd_image.show_switch" ${SOURCE_PATH}/config.json)
	local test_init cycle
	for ((test_init=1;test_init<=${ssd_cycle};test_init++))
	do
		ssd_cpu_temp_check
		ssd_main_stress_write
		ssd_main_stress_read
		let cycle=${test_init}%${ssd_show_image}
		if [ "${cycle}" -eq 0 ]
		then
			ssd_output_png
			ssd_output_html
			if [ "${ssd_switch_image}" -eq 1 ]
			then
				timeout 20 firefox ${R_P_LOG_SSD}/ssd_monitor.html > ${C_D_NULL} 2>&1
			fi
		fi
	done
}

ssd_output_png(){
	local read_speed_cache=$(awk -F "," '{print $5}' $R_P_LOG_SSD/ssd_read_statistic.log|awk -F "." '{print $1}' |sort -n)
	local read_speed_max=$(echo "$read_speed_cache" |tail -1)
	let read_yrange_max=$read_speed_max+200
	local write_speed=$(awk -F "," '{print $8}' $R_P_LOG_SSD/ssd_write_statistic.log |awk '{print $1}' |sort -n)
	local write_speed_max=$(echo "$write_speed" |tail -1)
	let write_yrange_max=$write_speed_max+200
	echo "
	set terminal png size 1280,720
	set output \"${R_P_LOG_SSD}/ssd_${SSD_CPU_NUM}.png\"
	set border lc rgb \"orange\"
	set multiplot layout 1,2
	set grid x,y lc rgb \"orange\"
	set datafile sep ','
	set origin 0,0
	set title \"ssd \($SSD_TYPE\) read speed\" font \",17\"
	set key box reverse
	set xlabel \"times\" font \",15\"
	set ylabel \"speed : MB/sec\" font \",15\"
	set xrange [-2:$test_init]
	set yrange [-200:$read_yrange_max]
	set ytics 200
	plot \"$R_P_LOG_SSD/ssd_read_statistic.log\" u 5 smooth csplines w l lc 1 lw 2 t \"read speed \(cache\)\",\
	'' u 6 smooth csplines w l lc 6 lw 2 t \"read speed \(buffer\)\",\
	'' u 7 smooth csplines w l lc 2 lw 2 t \"envir temp\",\
	'' u 8 smooth csplines w l lc 8 lw 2 t \"cpu-a rate\"
	set origin 0.5,0
	set title \"ssd \($SSD_TYPE\) write speed\" font \",17\"
	set xlabel \"times\" font \",15\"
	set ylabel \"speed : MB/sec\" font \",15\"
	set xrange [-2:$test_init]
	set yrange [-100:$write_yrange_max]
	set ytics 50
	set key box reverse
	plot \"$R_P_LOG_SSD/ssd_write_statistic.log\" u 8 smooth csplines w l lc 7 lw 2 t \"write speed\",\
	'' u 9 smooth csplines w l lc 2 lw 2 t \"envir temp\",\
	'' u 10 smooth csplines w l lc 8 lw 2 t \"cpu-a rate\" " |gnuplot
}

ssd_output_html(){
	local time_s=$(awk -F "," '{print $1}' ${R_P_LOG_SSD}/ssd_read_statistic.log |head -1)	
	local time_e=$(awk -F "," '{print $1}' ${R_P_LOG_SSD}/ssd_read_statistic.log |tail -1)	
	local head_m="SSD Read/Write status monitor (${time_s} to ${time_e})"
	echo "
	<!DOCTYPE html>
	<html>
		<head>
			<meta charset="utf-8">
			<title>ssd status monitor</title>
			<link rel="icon" type="image/x-icon" href="${R_P_LIB_HTML}/uisee.png">
			<link rel="stylesheet" type="text/css" href="${R_P_LIB_HTML}/html_style.css">
		</head>
		<body>
			<div>
				<hr />
				<h2>${head_m}</h2>
				<hr />
			</div>
			<div>
				<hr />
				<img src="${R_P_LOG_SSD}/ssd_${SSD_CPU_NUM}.png">
				<hr />
			</div>
		</body>
	</html>
	" > ${R_P_LOG_SSD}/ssd_monitor.html	
}

ssd_main_stress(){
	# main program ssd function excution
	local ssd_mount_path=$(jq -r ".para_ssd.ssd_mounted" ${SOURCE_PATH}/config.json)
	local ssd_type=$(jq -r ".para_ssd.ssd_type" ${SOURCE_PATH}/config.json)
	ssd_config_para_check
	ssd_dependency_package
	ssd_cpu_stress &
	if [ ! -d ${R_P_LOG_SSD} ]
	then
		mkdir -p  ${R_P_LOG_SSD}
	fi
	ssd_main_stress_template
}
