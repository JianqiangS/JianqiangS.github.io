#!/bin/bash
SOURCE_PATH=/home/worker/GG31_SYSTEM
source ${SOURCE_PATH}/etc/common.sh
source ${SOURCE_PATH}/etc/function.sh
source ${SOURCE_PATH}/etc/install_deb.sh

statistic_dependency_package(){
	# dependency package installation
	install_deb_check "csvlook" install_deb_csvkit
	install_deb_check "firefox" install_deb_firefox
	install_deb_check "gnuplot" install_deb_gnuplot
	install_deb_check "mail" install_deb_heirloom_mailx
	install_deb_check "uuencode" install_deb_uuencode
}

statistic_apu_normal_error(){
	# search for apu normal log error
	{
	if [ -f $subfile/apu_sf_statistic.log ]
	then
		tail -1 $subfile/apu_sf_statistic.log
	fi
	} | tee -a ${R_P_LOG_STATISTIC}/${D_FORMAT}-statistic-apu-normal.log
}

statistic_apu_normal_per_result(){
	# statistic apu normal log per result
	local apu_normal_log=${R_P_LOG_STATISTIC}/${D_FORMAT}-statistic-apu-normal.log
	if [ -f "${apu_normal_log}" ]
	then
		local apu_normal_succ=$(awk -F "," '{print $7}' ${apu_normal_log})
		local i apu_s_n=0
		for i in $(echo "${apu_normal_succ}")
		do
			let apu_s_n=$i+$apu_s_n
		done

		local apu_normal_fail=$(awk -F "," '{print $9}' ${apu_normal_log})
		local ii apu_f_n=0
		for ii in $(echo "${apu_normal_fail}")
		do
			let apu_f_n=$ii+$apu_f_n
		done
		printf "$(date "+%F_%T"),master,apu,upgrade_normal,${apu_s_n},${apu_f_n}\n"
	fi
}

statistic_apu_abnormal_error(){
	# search for apu abnormal log error
	{
	if [ -f $subfile/apu_sf_statistic.log ]
	then
		tail -1 $subfile/apu_sf_statistic.log
	fi
	} | tee -a ${R_P_LOG_STATISTIC}/${D_FORMAT}-statistic-apu-abnormal.log
}

statistic_apu_abnormal_per_result(){
	# statistic apu abnormal log per result
	local apu_abnormal_log=${R_P_LOG_STATISTIC}/${D_FORMAT}-statistic-apu-abnormal.log
	if [ -f "${apu_abnormal_log}" ]
	then
		local apu_abnormal_succ=$(awk -F "," '{print $9}' ${apu_abnormal_log})
		local i apu_s_a=0
		for i in $(echo "${apu_abnormal_succ}")
		do
			let apu_s_a=$i+$apu_s_a
		done

		local apu_abnormal_fail=$(awk -F "," '{print $11}' ${apu_abnormal_log})
		local ii apu_f_a=0
		for ii in $(echo "${apu_abnormal_fail}")
		do
			let apu_f_a=$ii+$apu_f_a
		done
		printf "$(date "+%F_%T"),master,apu,upgrade_abnormal,${apu_s_a},${apu_f_a}\n"
	fi
}

statistic_cdu_error(){
	# search for cdu log error
	{
	if [ -f $subfile/cdu_video0_master.log ]
	then
		tail -1 $subfile/cdu_video0_master.log
	fi
	if [ -f $subfile/cdu_video1_master.log ]
	then
		tail -1 $subfile/cdu_video1_master.log
	fi
	if [ -f $subfile/cdu_video0_slave.log ]
	then
		tail -1 $subfile/cdu_video0_slave.log
	fi
	if [ -f $subfile/cdu_video1_slave.log ]
	then
		tail -1 $subfile/cdu_video1_slave.log
	fi
	} | tee -a ${R_P_LOG_STATISTIC}/${D_FORMAT}-statistic-cdu.log
}

statistic_cdu_per_result(){
	# statistic cdu per result
	local video_info=$(grep "$1" ${R_P_LOG_STATISTIC}/${D_FORMAT}-statistic-cdu.log |grep "$2")
	local video_succ=$(echo "${video_info}" |awk -F "," '{print $6}')
	local i video_s_n=0
	for i in $(echo "$video_succ")
	do
		let video_s_n=${video_s_n}+${i}
	done

	local video_fail=$(echo "${video_info}" |awk -F "," '{print $7}')
	local ii video_f_n=0
	for ii in $(echo "$video_fail")
	do
		let video_f_n=${video_f_n}+${ii}
	done
	printf "$(date "+%F_%T"),$1,cdu,$2,${video_s_n},${video_f_n}\n"
}

statistic_cdu_all_result(){
	# statistic cdu all result
	local cdu_log=${R_P_LOG_STATISTIC}/${D_FORMAT}-statistic-cdu.log
	if [ -f "${cdu_log}" ]
	then
		statistic_cdu_per_result "master" "video0"
		statistic_cdu_per_result "master" "video1"
		statistic_cdu_per_result "slave" "video0"
		statistic_cdu_per_result "slave" "video1"
	fi
}

statistic_can_error(){
	# search for can log error
	can_record=$(sudo tail -8 $subfile/can_statistic.log |grep -am 1 -A 3 BCAN)
	echo "$can_record" |sudo tee -a ${STA_LOG}/${DATE}_statistic_check_can.log
}

statistic_can_per_result(){
	# statistic can per result
	declare -i can_s_n=0 can_f_n=0
	can_info=$(grep -a "$1" ${STA_LOG}/${DATE}_statistic_check_can.log)
	can_s=$(echo "$can_info" |awk '{print $14}')
	can_f=$(echo "$can_info" |awk '{print $19}')
	for i1 in $(echo "$can_s")
	do
		let can_s_n=$can_s_n+$i1
	done
	for i2 in $(echo "$can_f")
	do
		let can_f_n=$can_f_n+$i2
	done
	echo -e "${LINE}| $(date "+%F %T") | M_PORT | $1     | success : ${can_s_n} | fail : ${can_f_n} |${RES}"
}

statistic_can_all_result(){
	# statisitc can all result
	if [ -f "${STA_LOG}/${DATE}_statistic_check_can.log" ]
	then
		statistic_can_per_result "BCAN"
		statistic_can_per_result "PCAN"
		statistic_can_per_result "CAN3"
		statistic_can_per_result "CAN4"
	fi
}

statistic_dgps_error(){
	# search for dgps log error
	{
	if [ -f $subfile/dgps_statistic.log ]
	then
		tail -1 $subfile/dgps_statistic.log
	fi
	} | tee -a ${R_P_LOG_STATISTIC}/${D_FORMAT}-statistic-dgps.log
}

statistic_dgps_per_result(){
	# statistic dgps per result
	local dgps_log=${R_P_LOG_STATISTIC}/${D_FORMAT}-statistic-dgps.log
	if [ -f "${dgps_log}" ]
	then
		local dgps_succ=$(awk -F "," '{print $6}' ${dgps_log})
		local i dgps_s_f=0
		for i in $(echo "${dgps_succ}")
		do
			let dgps_s_f=$i+$dgps_s_f
		done

		local dgps_fail=$(awk -F "," '{print $7}' ${dgps_log})
		local ii dgps_f_f=0
		for ii in $(echo "${dgps_fail}")
		do
			let dgps_f_f=$ii+$dgps_f_f
		done
		printf "$(date "+%F_%T"),master,dgps,frame,${dgps_s_f},${dgps_f_f}\n"
	fi
}

statistic_iperf_error(){
	# search for iperf log error
	{
	if [ -f $subfile/iperf_statistic.log ]
	then
		tail -1 $subfile/iperf_statistic.log
	fi
	} | tee -a ${R_P_LOG_STATISTIC}/${D_FORMAT}-statistic-iperf.log  
}

statistic_iperf_per_result(){
	# statistic iperf per result
	local iperf_log=${R_P_LOG_STATISTIC}/${D_FORMAT}-statistic-iperf.log
	if [ -f "${iperf_log}" ]
	then
		local iperf_succ=$(awk -F "," '{print $5}' ${iperf_log})
		local i iperf_s_n=0
		for i in $(echo "${iperf_succ}")
		do
			let iperf_s_n=$i+$iperf_s_n
		done

		local iperf_fail=$(awk -F "," '{print $6}' ${iperf_log})
		local ii iperf_f_n=0
		for ii in $(echo "${iperf_fail}")
		do
			let iperf_f_n=$ii+$iperf_f_n
		done
		local iperf_port=$(awk -F ',' '{print $2}' ${iperf_log} |tail -1)
		printf "$(date "+%F_%T"),${iperf_port},iperf,<1%%,${iperf_s_n},${iperf_f_n}\n"
	fi
}

statistic_net_error(){
	# search for net ping log error
	{
	if [ -f $subfile/ping_statistic.log ]
	then
		tail -1 $subfile/ping_statistic.log
	fi
	} | tee -a ${R_P_LOG_STATISTIC}/${D_FORMAT}-statistic-net.log  
}

statistic_net_per_result(){
	# statistic ping net per result
	local net_log=${R_P_LOG_STATISTIC}/${D_FORMAT}-statistic-net.log
	if [ -f "${net_log}" ]
	then
		local net_total=$(awk -F "," '{print $4}' ${net_log})
		local i net_t_n=0
		for i in $(echo "${net_total}")
		do
			let net_t_n=$i+$net_t_n
		done

		local net_succ=$(awk -F "," '{print $5}' ${net_log})
		local ii net_s_n=0 net_f_n=0
		for ii in $(echo "${net_succ}")
		do
			let net_s_n=$ii+$net_s_n
		done
		let net_f_n=${net_t_n}-${net_s_n}
		local net_mode=$(awk -F ',' '{print $3}' ${net_log} |tail -1)
		printf "$(date "+%F_%T"),master,network,${net_mode},${net_s_n},${net_f_n}\n"
	fi
}

statistic_cpu_error(){
	# search for cpu status log error
	{
	if [ -f $subfile/cpu_master_statistic.log ]
	then
		tail -1 $subfile/cpu_master_statistic.log
	fi
	if [ -f $subfile/cpu_slave_statistic.log ]
	then
		tail -1 $subfile/cpu_slave_statistic.log
	fi
	} | tee -a ${R_P_LOG_STATISTIC}/${D_FORMAT}-statistic-cpu.log
}

statistic_gpu_error(){
	# search for gpu status log error
	{
	if [ -f $subfile/gpu_master_statistic.log ]
	then
		tail -1 $subfile/gpu_master_statistic.log
	fi
	if [ -f $subfile/gpu_slave_statistic.log ]
	then
		tail -1 $subfile/gpu_slave_statistic.log
	fi
	} | tee -a ${R_P_LOG_STATISTIC}/${D_FORMAT}-statistic-gpu.log
}

statistic_dsi_error(){
	# search for dsi status log error
	{
	if [ -f $subfile/dsi_statistic.log ]
	then
		tail -1 $subfile/dsi_statistic.log
	fi
	} | tee -a ${R_P_LOG_STATISTIC}/${D_FORMAT}-statistic-dsi.log
}

statistic_dsi_per_result(){
	# statistic tx2i dsi display log per result
	local dsi_log=${R_P_LOG_STATISTIC}/${D_FORMAT}-statistic-dsi.log
	if [ -f "${dsi_log}" ]
	then
		local dsi_succ=$(awk -F "," '{print $5}' ${dsi_log})
		local i dsi_s_f=0
		for i in $(echo "${dsi_succ}")
		do
			let dsi_s_f=$i+$dsi_s_f
		done

		local dsi_fail=$(awk -F "," '{print $6}' ${dsi_log})
		local ii dsi_f_f=0
		for ii in $(echo "${dsi_fail}")
		do
			let dsi_f_f=$ii+$dsi_f_f
		done
		printf "$(date "+%F_%T"),master,dsi,display,${dsi_s_f},${dsi_f_f}\n"
	fi
}

statistic_temp_error(){
	# serach for temp log error 
	{
	if [ -f $subfile/temp_master_statistic.log ]
	then
		tail -1 $subfile/temp_master_statistic.log
	fi
	if [ -f $subfile/temp_slave_statistic.log ]
	then
		tail -1 $subfile/temp_slave_statistic.log
	fi
	} | tee -a ${R_P_LOG_STATISTIC}/${D_FORMAT}-statistic-temp.log
}

statistic_module_attribute(){
	if [ -d "${subfile}" ]
	then
		printf "${module_name} : ${subfile}\n"
		# judge current file attributes
		case ${module_name} in 
		"check_apu/normal")
			statistic_apu_normal_error
		;;
		"check_apu/abnormal")
			statistic_apu_abnormal_error
		;;
		"check_can")
			statistic_can_error
		;;
		"check_cdu")
			statistic_cdu_error
		;;
		"check_cpu")
			statistic_cpu_error
		;;
		"check_dgps")
			statistic_dgps_error
		;;
		"check_dsi")
			statistic_dsi_error
		;;
		"check_gpu")
			statistic_gpu_error
		;;
		"check_iperf")
			statistic_iperf_error
		;;
		"check_network")
			statistic_net_error
		;;
		"check_temp")
			statistic_temp_error
		;;
		esac
	fi
}

statistic_main_program(){
	if [ ! -d "${R_P_LOG_STATISTIC}" ]
	then
		mkdir -p ${R_P_LOG_STATISTIC}
	fi
	for module_name in $(cat ${SOURCE_PATH}/etc/search_exception.txt)
	do
		main_path=${SOURCE_PATH}/log/${module_name}
		if [ -d "${main_path}" ]
		then
			echo "${S_L_STR0// /-}"
			printf "start to check ${main_path} log directory\n"
			# view the number of files in the ${main_path} directory
			module_file_num=$(ls -l ${main_path} |grep "^d" -c)
			printf "${C_B_BLUE}${module_name}${C_F_RES} contain subdirectory num ${C_B_RED}${module_file_num}${C_F_RES}\n"
			if [ "${module_file_num}" -gt 0 ]
			then
				# enter each subfile under the ${main_path} directory 
				for subfile in ${main_path}/*
				do
					sudo chown -R worker:worker $subfile
					statistic_module_attribute
					sleep 0.5
				done
			else
				printf "${main_path} directory not contain subdirectory ...\n"
			fi
		else
			printf "${main_path} log directory not exist ...\n"
		fi
	done
	echo "${S_L_STR0// /-}"
}

statistic_all_function_result(){
	# output all function statistic result 
	printf "date,port,progrem,sub_progrem,succ_num,fail_num\n"
	statistic_apu_normal_per_result
	statistic_apu_abnormal_per_result
	statistic_cdu_all_result
	statistic_dgps_per_result
	statistic_net_per_result
	statistic_dsi_per_result
	statistic_iperf_per_result
#	statistic_can_all_result
}

statistic_mail_send(){
	# send statistic log
	cd ${R_P_LOG_STATISTIC}
	tar -czvf ${D_FORMAT}-gg31-statistic.tar.gz ./*.log > ${C_D_NULL} 
	{
	uuencode ${D_FORMAT}-gg31-statistic.tar.gz ${D_FORMAT}-gg31-statistic.tar.gz
	} | mail -s "`date "+%F_%T"` GG31 Statistic Result" 13734716682@163.com < ${R_P_LOG_STATISTIC}/${D_FORMAT}-statistic.log
	sync
	rm -rf ${D_FORMAT}-gg31-statistic.tar.gz
}

statistic_data_rollback(){
	# statistic data rollback
	local roll_back_num=$(jq -r ".para_statistic.rollback_threshold" ${SOURCE_PATH}/config.json)
	local statistic_directory=${R_P_LOG}/check_statistic
	local statistic_directory_num=$(ls -l ${statistic_directory} |grep -c "^d")
	local statistic_directory_name=$(ls -l ${statistic_directory} |awk '{print $9}' |tail -${statistic_directory_num} |sort)
	if [ "${statistic_directory_num}" -ge "${roll_back_num}" ]
	then
		# delete half storage log file
		let "del_num=${statistic_directory_num}/2"
		local init_num=0
		for index_del in $(echo "${statistic_directory_name}")
		do
			{
			printf "$(date "+%F_%T") : delete ${statistic_directory}/${index_del}\n"
			} >> ${R_P_LOG}/roll_back.txt
			rm -rf ${statistic_directory}/${index_del}
			let init_num=$init_num+1
			if [ "${init_num}" -eq "${del_num}" ]
			then
				break
			fi
		done
	fi
}

statistic_crontab_status(){
	local json_cron_md5sum=$(jq -r ".para_statistic.cron_md5sum" ${SOURCE_PATH}/config.json)
	local etc_cron_md5sum=$(md5sum /etc/crontab)
	if [ "${json_cron_md5sum}"x != "${etc_cron_md5sum}"x ]
	then
		sudo cp ${R_P_LIB_FILE}/file_cron/crontab /etc
	fi
}

statistic_output_html(){
	# output statistic error html
	local head_m="GG3.1 statistic error output"
	local statistic_info=$(csvlook ${R_P_LOG_STATISTIC}/${D_FORMAT}-statistic.log)
	echo "
	<!DOCTYPE html>
	<html>
		<head>
			<meta charset="utf-8">
			<title>statistic error</title>
			<link rel="icon" type="image/x-icon" href="${R_P_LIB_HTML}/uisee.png">
			<link rel="stylesheet" type="text/css" href="${R_P_LIB_HTML}/html_style.css">
		</head>
		<body>
			<div>
				<hr />
				<h2>$head_m</h2>
				<hr />
				<pre>$statistic_info</pre>
				<hr />
			</div>
		</body>
	</html>
	" > ${R_P_LOG_STATISTIC}/statistic.html
}

statistic_interface(){
	local statistic_switch_image=$(jq -r ".para_statistic.show_switch" ${SOURCE_PATH}/config.json)
	local statistic_switch_mail=$(jq -r ".para_statistic.mail_switch" ${SOURCE_PATH}/config.json)
	statistic_dependency_package
	statistic_main_program
	#printf "\n"
	{
	statistic_all_function_result
	} > ${R_P_LOG_STATISTIC}/${D_FORMAT}-statistic.log
	statistic_output_html
	if [ "${statistic_switch_image}" -eq 1 ]
	then
		timeout 20 firefox ${R_P_LOG_STATISTIC}/statistic.html > ${C_D_NULL} 2>&1
	fi
	if [ "${statistic_switch_mail}" -eq 1 ]
	then
		statistic_mail_send
	fi
	statistic_crontab_status
	statistic_data_rollback
}
