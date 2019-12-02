#!/bin/bash
SOURCE_PATH=/home/worker/GG31
source ${SOURCE_PATH}/etc/common.sh
source ${SOURCE_PATH}/etc/function.sh

check_tx2i_master_upgrade(){
	# check tx2i os differential upgrade
	function_lever_first_master "os system differential upgrade"
	local os_path=${R_P_LIB_FILE}/os_cfg
	local os_file=$(ls ${os_path} |sort -n)
	if [ -n "${os_file}" ]
	then
		for i in ${os_file}
		do
			function_lever_second_master "system config status info"	
			cat /etc/sys_cfg_rec
			function_lever_second_master "os system upgrade ($i)"
			printf "apply_os.sh -f ${os_path}/$i\n"
			apply_os.sh -f ${os_path}/$i
		done
	else
		printf "${C_F_LINE}[ Check ] : ${os_path} not contain os_img file${C_F_RES}\n"
	fi
	echo -e "${S_L_STR0// /-}\n"
}

check_tx2i_master_version(){
	# check tx2i hardware and software version
	function_lever_first_master "version"
	function_lever_second_master "hardware and software version info"
	list_version.sh
	echo -e "${S_L_STR0// /-}\n"
}

check_tx2i_master_config(){
	# check tx2i master config
	function_lever_first_master "configuration parameter"
	function_lever_second_master "boot dmesg info"
	sleep 1 && dmesg | grep -i "error"
	sleep 1 && dmesg | grep -i "fail"
	function_lever_second_master "network configuration info"
	sleep 1 && ifconfig
	function_lever_second_master "rc.local service status"
	sleep 1 && systemctl status rc.local.service |head -30
	function_lever_second_master "${F_P_HOME} memory space info"
	sleep 1 && df -ahl
	function_lever_second_master "os version info"
	sleep 1 && jq . /etc/uisee_release
	function_lever_second_master "mount kernal driver info"
	sleep 1 && lsmod
	function_lever_second_master "videonode info"
	sleep 1 && ls -l /dev/video*
	function_lever_second_master "camera in-position status"
	sleep 1 && config_ub964.sh
	function_lever_second_master "list ${F_P_APU_HOST} file"
	sleep 1 && ls -l ${F_P_APU_HOST}
	function_lever_second_master "list ${F_P_APU_TARGET} file"
	sleep 1 && ls -l ${F_P_APU_TARGET}
	function_lever_second_master "cpu & temperature info"
	sleep 1 && sudo timeout 3 ${F_P_HOME}/tegrastats
	function_lever_second_master "cpu & gpu frequency info"
	sleep 1 && sudo ${F_P_HOME}/jetson_clocks.sh --show
	function_lever_second_master "module power status"
	sleep 1 && module_power_ctrl.sh diag
	echo -e "${S_L_STR0// /-}\n"
}

check_tx2i_slave_config(){
	# check tx2i slave config
	function_lever_first_slave "configuration parameter"
	function_lever_second_master "boot dmesg info"
	ssh slave "sleep 1 && dmesg | grep -i "error""
	ssh slave "sleep 1 && dmesg | grep -i "fail""
	function_lever_second_master "network configuration info"
	ssh slave "sleep 1 && ifconfig"
	function_lever_second_master "rc.local service status"
	ssh slave "sleep 1 && systemctl status rc.local.service |head -25"
	function_lever_second_master "${F_P_HOME} memory space info"
	ssh slave "sleep 1 && df -ahl"
	function_lever_second_master "os version info"
	ssh slave "sleep 1 && jq . /etc/uisee_release"
	function_lever_second_master "mount kernal driver info"
	ssh slave "sleep 1 && lsmod"
	function_lever_second_master "videonode info"
	ssh slave "sleep 1 && ls -l /dev/video*"
	function_lever_second_master "camera in-position status"
	ssh slave "sleep 1 && config_ub964.sh"
	function_lever_second_master "ic2 bus of video status info"
	ssh slave "sudo i2cdetect -y -r 2"
	function_lever_second_master "upgrade weisen camera file"
	ssh slave "sleep 1 && ls -l ${F_P_ISP}"
	function_lever_second_master "cpu & temperature info"
	ssh slave "sleep 1 && sudo timeout 3 ${F_P_HOME}/tegrastats"
	function_lever_second_master "cpu & gpu frequency info"
	ssh slave "sleep 1 && sudo ${F_P_HOME}/jetson_clocks.sh --show"
	function_lever_second_master "view display status info"
	ssh slave "sleep 1 && sudo gmsl_i2c_op r 0x48 0x03"
	echo -e "${S_L_STR0// /-}\n"
}

check_tx2i_master_connect(){
	# check tx2i master && slave interconnect
	function_lever_first_master "interconnect"
	function_lever_second_master "master access slave through domain name"
	printf "ssh slave and output slave port ip\n"
	sleep 1 && ssh slave "ifconfig eth0"
	function_lever_second_master "master access slave through ip"
	printf "ssh ${P_I_SLAVE} and output slave port ip\n"
	sleep 1 && ssh ${P_I_SLAVE} "ifconfig eth0"
	function_lever_second_master "master and slave interconnect mode 1"
	sleep 1 && ping -c ${tx2i_ping_num} slave
	function_lever_second_master "master and slave interconnect mode 2"
	sleep 1 && ping -c ${tx2i_ping_num} ${P_I_SLAVE}
	echo -e "${S_L_STR0// /-}\n"
}

check_tx2i_slave_connect(){
	# check tx2i slave && master interconnect
	function_lever_first_slave "interconnection"
	function_lever_second_master "slave access master through domain name"
	sleep 1 && ssh slave "echo "Current port is slave port"\
	&& ifconfig eth0 \
	&& echo "After access is master port" \
	&& ssh master "ifconfig eth0""
	function_lever_second_master "slave access master through ip"
	sleep 1 && ssh slave "echo "Current port is slave port"\
	&& ifconfig eth0 \
	&& echo "After access is master port" \
	&& ssh ${P_I_MASTER} "ifconfig eth0""
	function_lever_second_master "slave and master interconnect mode 1"
	sleep 1 && ssh slave "echo "Current port is slave port"\
	&& ifconfig eth0 \
	&& ping -c ${tx2i_ping_num} master"
	function_lever_second_master "slave and master interconnect mode 2"
	sleep 1 && ssh slave "echo "Current port is slave port"\
	&& ifconfig eth0 \
	&& ping -c ${tx2i_ping_num} ${P_I_MASTER}"
	function_lever_second_master "slave access network: ${P_I_NET}"
	sleep 1 && ssh slave "echo "Current port is slave port"\
	&& ifconfig eth0 \
	&& ping -c ${tx2i_ping_num} ${P_I_NET}\
	&& ping -c ${tx2i_ping_num} www.baidu.com"
	echo -e "${S_L_STR0// /-}\n"
}

check_tx2i_uos_upload(){
	# check tx2i uos_log uploads
	function_lever_second_master "change upload logs address to $1"
	/usr/bin/expect << eeooff
		spawn sudo switch_upload_logs.sh
		expect "Pick a project:"
		send "$2\r"
		expect "OK"
		interact
eeooff
	local result=$(head -3 /usr/local/bin/upload_logs.sh |tail -2)
	# check switch upload address 
	echo "${result}" |grep $3
	if [ "$?" -eq 0 ]
	then
		local state="success"
	else
		local state="fail"
	fi
	printf "${C_F_LINE}[ Check ] : switch uos_log upload address $1 ${state}${C_F_RES}\n"
	upload_logs.sh && sleep 3
}

check_tx2i_master_uos_ftp(){
	function_lever_second_master "ftp function info"
	local gg_ftp_dir=${F_P_HOME}/UISEE_LOGS/${tx2i_uos_name}
	local pc_ftp_dir=/home/uisee/init_pc/Documents/16_GG31/3_result/ftp
	local ftp_user=turtle
	local ftp_pass=turtle
	ssh uisee@192.168.100.66 << EOF
		ftp -n << eeooff
			open ${P_I_MASTER}
			user ${ftp_user} ${ftp_pass}
			binary
			cd ${gg_ftp_dir}
			lcd ${pc_ftp_dir}
			hash
			prompt off
			mget *.*
			close
			bye
		eeooff
EOF
}

check_tx2i_master_uos(){
	# check tx2i uos system
	function_lever_first_master "uos system"
	function_lever_second_master "launch uos system info"
	local tx2i_uos_name=$(jq -r ".set_uos_name" ${SOURCE_PATH}/config.json)
	local uos_name=${F_P_HOME}/${tx2i_uos_name}/run
	if [ -d "${uos_name}" ]
	then 
		cd ${uos_name}  && timeout 20 ./launch_uos.sh
		function_lever_second_master "/opt path compass file property info"
		ls -l /opt
		function_lever_second_master "uisee_io_dispatch service status"
		systemctl status uisee_io_dispatch.service |head -25
		function_lever_second_master "uisee_gps_dispatch service status"
		systemctl status uisee_gps_dispatch.service |head -25
		function_lever_second_master "uisee_log_daemon service status"
		systemctl status uisee_log_daemon.service |head -25
		function_lever_second_master "enable ftp switch info"
		switch_ftp.sh enable
		function_lever_second_master "UISEE_LOGS file mount info"
		df -ahl |grep UISEE_LOGS
		function_lever_second_master "ftp service status"
		systemctl status vsftpd.service |head -25
		#check_tx2i_master_uos_ftp
		function_lever_second_master "enable rsync switch info"
		switch_rsync.sh enable
		check_tx2i_uos_upload "Fang Shan" 1 "fs"
		check_tx2i_uos_upload "Liu Zhou" 2 "lz"
		check_tx2i_uos_upload "Yu Tong" 3 "yt"
		#function_lever_second_master "disable rsync switch info"
		#switch_rsync.sh disable
		#function_lever_second_master "disable ftp switch info"
		#switch_ftp.sh disable
	else
		printf "${C_F_LINE}[ Check ] : ${SOURCE_PATH}/config.json set_uos_name error${C_F_RES}\n"
	fi
	echo -e "${S_L_STR0// /-}\n"
}

check_tx2i_master_time(){
	# check master time sync
	function_lever_first_master "time sync"
	function_lever_second_master "master port and slave port current time synchronize"
	function_time_sync
	function_lever_second_master "chrony service status"
	systemctl status chrony.service |head -30
	function_lever_second_master "slave port time synchronize master port"
	printf "Modify master port time and write hardware\n"
	printf "uisee\n"|sudo -S date -s "${tx2i_date_change}" & 
	sleep 1
	sudo hwclock -w &
	function_progress_bar 0.45
	printf "\nAfter 45 seconds minute,check if master and slave synchronize time\n"
	function_time_sync
	function_lever_second_master "time synchronize current system time"
	function_progress_bar 2.55
	printf "\nAfter 300 seconds,check if master/slave synchronize the current time\n"
	function_time_sync
	echo -e "${S_L_STR0// /-}\n"
}

check_tx2i_slave_time(){
	# check slave time sync
	function_lever_first_slave "time sync"
	function_lever_second_master "current slave & master port time"
	function_time_sync
	function_lever_second_master "chrony service status"
	ssh ${P_I_SLAVE} "systemctl status chrony.service |head -30"
	function_lever_second_master "slave port time synchronize master port time"
	printf "Modify slave time and write hardware\n"
	ssh ${P_I_SLAVE} "sudo date -s "${tx2i_date_change}""
	ssh ${P_I_SLAVE} "sudo hwclock -w &"
	function_progress_bar 0.3
	printf "\nAfter 30 seconds, check if slave/master synchronize time\n"
	function_time_sync
	function_lever_second_master "slave port time synchronize the current system time"
	function_progress_bar 0.3
	printf "\nAfter 60 seconds, check if master/slave synchronize the current time\n"
	function_time_sync
	echo -e "${S_L_STR0// /-}\n"
}

check_tx2i(){
	# check tx2i module all function 
	local tx2i_ping_num=$(jq -r ".para_tx2i.tx2i_ping_num" ${SOURCE_PATH}/config.json)
	local tx2i_date_change=$(jq -r ".para_tx2i.tx2i_date_change" ${SOURCE_PATH}/config.json)
	check_tx2i_master_upgrade
	check_tx2i_master_version
	check_tx2i_master_config
	check_tx2i_slave_config
	check_tx2i_master_connect
	check_tx2i_slave_connect
	check_tx2i_master_uos
	check_tx2i_master_time
	check_tx2i_slave_time
}
