#!/bin/bash
SOURCE_PATH=/home/worker/GG31_SYSTEM
source ${SOURCE_PATH}/etc/common.sh
source ${SOURCE_PATH}/etc/function.sh
source ${SOURCE_PATH}/etc/install_deb.sh

gpu_dependency_package(){
	# dependency package installation
	install_deb_check "csvlook" install_deb_csvkit
	install_deb_check "firefox" install_deb_firefox
	install_deb_check "gnuplot" install_deb_gnuplot
}

gpu_config_para_check(){
	# check deploy uos package
	if [ ! -d "${gpu_uos_path}" ]
	then
		printf "$gpu_uos_path not exist\n"
		printf "please check ${SOURCE_PATH}/config.json gpu_uos\n"
		exit 1
	fi
}

gpu_dependency_file(){
	# check gpu relay file
	local matrixmul_file=${gpu_uos_path}/matrixMul.dat
	if [ ! -f "${matrixmul_file}" ]
	then
		cp ${R_P_LIB_FILE}/file_gpu/matrixMul.dat ${gpu_uos_path}
	fi
	matrixmul_file_s=$(ssh slave "ls -l ${matrixmul_file}")
	if [ -z "${matrixmul_file_s}" ]
	then
		scp ${R_P_LIB_FILE}/file_gpu/matrixMul.dat slave:${gpu_uos_path}
	fi
}

gpu_main_stress_master(){
	# master port gpu program excute
	sudo killall matrixMul.dat
	cd ${gpu_uos_path}
	. set_env.sh
	./matrixMul.dat > ${C_D_NULL}
}

gpu_main_stress_slave(){
	# slave port gpu program excute
	ssh slave << eof
	sudo killall matrixMul.dat
	cd ${gpu_uos_path}
	. set_env.sh
	./matrixMul.dat > ${C_D_NULL}
eof
}

gpu_main_stress_kill(){
	# stop master and slave gpu program
	sudo killall matrixMul.dat
	ssh slave "sudo killall matrixMul.dat"
}

gpu_main_stress_both(){
	# excute gpu program
	gpu_main_stress_master &
	gpu_main_stress_slave &
}

gpu_result_status_check(){
	# check gpu freq and rate info template
	function_gpu_status_info "${tegrastats_info}"
	printf "$(date "+%F %T"),$1,gpu,${test_init},${gpu_rate},${gpu_freq}\n"
}

gpu_result_status_master(){
	# output master port gpu info
	local tegrastats_info=$(sudo timeout 2 /home/worker/tegrastats)
	gpu_result_status_check "master"
}

gpu_result_status_slave(){
	# output slave port gpu info
	local tegrastats_info=$(ssh slave "sudo timeout 2 /home/worker/tegrastats")
	gpu_result_status_check "slave"
}

gpu_result_statistic_template(){
	# gpu status information
	printf "date,port,project,test_num,gpu_rate,gpu_freq\n"
	gpu_result_status_master
	gpu_result_status_slave
}

gpu_output_png(){
	# output gpu rate and freq info with png mode
	echo "
	set terminal png size 1280,720
	set output \"${R_P_LOG_GPU}/gpu_out.png\"
	set multiplot layout 1,2
	set border lc rgb \"orange\"
	set xlabel \"times\" font \",15\"
	set ylabel \"gpu-f-r\" font \",15\"
	set xrange [-2:$test_init]
	set yrange [-100:1200]
	set xtics textcolor rgb \"orange\"
	set ytics 100 textcolor rgb \"orange\"
	set grid x,y lc rgb \"orange\"
	set key box reverse
	set datafile sep \",\"
	set origin 0,0
	set title \"GPU-Rate-Freq \(master\)\" font \",16\"
	plot \"${R_P_LOG_GPU}/gpu_master_statistic.log\" u 5 w l lw 2 lc 1 t 'GPU: R',\
	'' u 6 w l lw 2 lc 7 t 'GPU: F'
	set origin 0.5,0
	set title \"GPU-Rate-Freq \(slave\)\" font \",16\"
	plot \"${R_P_LOG_GPU}/gpu_slave_statistic.log\" u 5 w l lw 2 lc 1 t 'GPU: R',\
	'' u 6 w l lw 2 lc 7 t 'GPU: F' " |gnuplot
}

gpu_output_html(){
	local time_s=$(awk -F "," '{print $1}' ${R_P_LOG_GPU}/gpu_master_statistic.log |head -1)
	local time_e=$(awk -F "," '{print $1}' ${R_P_LOG_GPU}/gpu_master_statistic.log |tail -1)
	local head_m="GG3.1 gpu status monitor (${time_s} to ${time_e})"
	local gpu_info=$(csvlook ${R_P_LOG_GPU}/gpu_template.log)
	echo "
	<!DOCTYPE html>
	<html>
		<head>
			<meta charset="utf-8">
			<title>gpu status monitor</title>
			<link rel="icon" type="image/x-icon" href="${R_P_LIB_HTML}/uisee.png">
			<link rel="stylesheet" type="text/css" href="${R_P_LIB_HTML}/html_style.css">
		</head>
		<body>
			<div>
				<hr />
				<h2>${head_m}</h2>
				<hr />
				<pre>${gpu_info}</pre>
				<hr />
			</div>
			<div>
				<hr />
				<img src="${R_P_LOG_GPU}/gpu_out.png">
				<hr />
			</div>
		</body>
	</html>
	" > ${R_P_LOG_GPU}/gpu_monitor.html
}

gpu_result_statistic(){
	local delay_time=$(jq -r ".delay_time" ${SOURCE_PATH}/config.json)
	local gpu_cycle=$(jq -r ".para_gpu.gpu_cycle" ${SOURCE_PATH}/config.json)
	local gpu_image_show=$(jq -r ".para_gpu.gpu_image.show_interval" ${SOURCE_PATH}/config.json)
	local gpu_image_switch=$(jq -r ".para_gpu.gpu_image.show_switch" ${SOURCE_PATH}/config.json)
	local test_init cycle
	for ((test_init=1;test_init<=${gpu_cycle};test_init++))
	do
		sleep ${delay_time}
		gpu_result_statistic_template > ${R_P_LOG_GPU}/gpu_template.log
		csvlook ${R_P_LOG_GPU}/gpu_template.log
		tail -2 ${R_P_LOG_GPU}/gpu_template.log |head -1 >> ${R_P_LOG_GPU}/gpu_master_statistic.log
		tail -1 ${R_P_LOG_GPU}/gpu_template.log >> ${R_P_LOG_GPU}/gpu_slave_statistic.log
		let cycle=${test_init}%${gpu_image_show}
		if [ "${cycle}" -eq 0 ]
		then
			gpu_output_png
			gpu_output_html
			if [ "${gpu_image_switch}" -eq 1 ]
			then
				timeout 20 firefox ${R_P_LOG_GPU}/gpu_monitor.html > ${C_D_NULL} 2>&1
			fi
		fi
	done
}

gpu_main_stress(){
	local gpu_uos_name=$(jq -r ".para_gpu.gpu_uos" ${SOURCE_PATH}/config.json)
	local gpu_uos_path=/home/worker/${gpu_uos_name}/run
	gpu_config_para_check
	gpu_dependency_file
	gpu_dependency_package
	if [ ! -d "${R_P_LOG_GPU}" ]
	then
		mkdir -p ${R_P_LOG_GPU}
	fi
	gpu_main_stress_both 
	gpu_result_statistic
	gpu_main_stress_kill
}
