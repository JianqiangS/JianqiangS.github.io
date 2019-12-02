#!/bin/bash
MAIN_PATH=/home/worker/GG31_SYSTEM
source ${MAIN_PATH}/bin/monitor_cpu.sh
source ${MAIN_PATH}/etc/install_deb.sh
source ${MAIN_PATH}/bin/monitor_gpu.sh
source ${MAIN_PATH}/bin/monitor_iperf.sh
source ${MAIN_PATH}/bin/monitor_net.sh
source ${MAIN_PATH}/bin/monitor_temp.sh
source ${MAIN_PATH}/bin/statistic_error.sh
source ${MAIN_PATH}/bin/monitor_module/monitor_apu.sh
source ${MAIN_PATH}/bin/monitor_module/monitor_can.sh
source ${MAIN_PATH}/bin/monitor_module/monitor_cdu.sh
source ${MAIN_PATH}/bin/monitor_module/monitor_dgps.sh
source ${MAIN_PATH}/bin/monitor_module/monitor_dsi.sh
source ${MAIN_PATH}/bin/monitor_module/monitor_ssd.sh
source ${MAIN_PATH}/bin/monitor_module/monitor_system.sh

main_prompt_info(){
printf "${S_L_STR2// /*}
SYNOPSISI  :  $(basename $0)  [1|2|3|4|5|6|7|8|9|10|11|12|13]
${S_L_STR0// /-}
DESCRIPTION
${S_L_STR0// /-}
\t1   >  pressure test apu_main_stress
\t2   >  pressure test can_main_stress
\t3   >  pressure test cdu_main_stress
\t4   >  pressure test cpu_main_stress
\t5   >  pressure test dgps_main_stress
\t6   >  pressure test dsi_main_stress
\t7   >  pressure test gpu_main_stress
\t8   >  pressure test iperf_main_stress
\t9   >  pressure test net_main_stress
\t10  >  pressure test ssd_main_stress
\t11  >  pressure test temp_main_stress
\t12  >  pressure test monitor_system_show
\t13  >  test statistic_interface
${S_L_STR2// /*}\n"
}

main_dependency_package(){
	# Dependency package installation
	install_deb_check "csvlook" install_deb_csvkit
	install_deb_check "cutecom" install_deb_cutecom
	install_deb_check "expect" install_deb_expect
	install_deb_check "firefox" install_deb_firefox
	install_deb_check "gnuplot" install_deb_gnuplot
	install_deb_check "hdparm" install_deb_hdparm
	install_deb_check "stress-ng" install_deb_stress_ng
	install_deb_check "mail" install_deb_heirloom_mailx
	install_deb_check "uuencode" install_deb_uuencode
}

main_module_attributes(){
	# module attributes
	main_dependency_package
	case "$1" in
		1)
		apu_main_stress	
		;;
		2)
		can_main_stress
		;;
		3)
		cdu_main_stress
		;;
		4)
		cpu_main_stress
		;;
		5)
		dgps_main_stress
		;;
		6)
		dsi_main_stress
		;;
		7)
		gpu_main_stress
		;;
		8)
		iperf_main_stress
		;;
		9)
		net_main_stress
		;;
		10)
		ssd_main_stress
		;;
		11)
		temp_main_stress
		;;
		12)
		monitor_system_show
		;;
		13)
		statistic_interface
		;;		
		*)
		main_prompt_info
		exit 1
		;;
	esac
}

main_module_attributes $1
