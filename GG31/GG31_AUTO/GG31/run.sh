#!/bin/bash
SOURCE_PATH=/home/worker/GG31
source ${SOURCE_PATH}/bin/check_config.sh
source ${SOURCE_PATH}/bin/main_program.sh
source ${SOURCE_PATH}/etc/common.sh
source ${SOURCE_PATH}/etc/function.sh

config_unit_mktemp(){
	temp0=$(mktemp -t test0.XXXXXX)
	temp1=$(mktemp -t test1.XXXXXX)
	temp2=$(mktemp -t test2.XXXXXX)
	temp3=$(mktemp -t test3.XXXXXX)
	temp4=$(mktemp -t test4.XXXXXX)
	temp5=$(mktemp -t test5.XXXXXX)
	temp6=$(mktemp -t test6.XXXXXX)
	temp7=$(mktemp -t test7.XXXXXX)
	temp8=$(mktemp -t test8.XXXXXX)
	temp9=$(mktemp -t test9.XXXXXX)
	temp10=$(mktemp -t test10.XXXXXX)
	temp11=$(mktemp -t test11.XXXXXX)
	temp12=$(mktemp -t test12.XXXXXX)
	temp13=$(mktemp -t test13.XXXXXX)
}

get_window_size(){
	# get window width and height
	stty_height=$(stty size | awk '{print $1}')
	stty_width=$(stty size | awk '{print $2}')
	let box_height=$stty_height-5
	let box_width=$stty_width-10
}

config_doc_view(){
	# view config document
	local info_config=$(egrep "switch|set_uos_name" ${SOURCE_PATH}/config.json)
	whiptail --clear --fb\
	--title "GG3.1 System Config Document"\
	--backtitle "  UISEE DRIVER IDU SYSTEM"\
	--msgbox "\n$(echo "$info_config")" 20 70
	verification_config
}

uos_change_name(){
	# change defaultt uos_name 
	cat ${SOURCE_PATH}/config.json |
	jq --arg v $1 'to_entries |
		map(if .key == "set_uos_name"
		then . + {"value":$v}
		else .
		end
		) |
		from_entries' > ${SOURCE_PATH}/config.json.bak
}

config_unit_uos(){
	# config uos name 
	local uos_name=$(whiptail --clear --fb\
	--title "GG3.1 SYSTEM AUTO TEST"\
	--backtitle "  UISEE DRIVER IDU SYSTEM"\
	--inputbox "Please input the name of the deployment UOS package?"\
	10 60 uisee_1105 3>&1 1>&2 2>&3)
	if [ "$?" -eq 0 ]; then
		uos_change_name "$uos_name"
		mv ${SOURCE_PATH}/config.json.bak ${SOURCE_PATH}/config.json
	fi
	config_doc_view
}

config_unit_config(){
	# config unit enable or disable config
	while true
	do
		whiptail --clear --fb\
		--title "GG3.1 SYSTEM AUTO TEST"\
		--backtitle "  UISEE DRIVER IDU SYSTEM"\
		--menu "\n\n\n  GG3.1 system auto test\n\n\
		Copyright   :    Embedded system testing\n\
		Version     :    V4.0.0\n\
		Date        :    $(date "+%F %T %p")\n\
		Mac_address :    ${hwaddr}\n\
		Infomation  :    The GG31 system performance verification test covers the test cases that can be involved in the master and slave sides !\n\n\n"\
		30 90 4 1 "_ CONFIG  :    Module    $1     Switch    Enable"\
		2 "_ CONFIG  :    Module    $1     Switch    Disable" 2> $2
		selection=$(cat $2)
		case $selection in
			1)
			$3
			config_doc_view;;
			2)
			$4
			config_doc_view;;
			*)
			verification_config ;;
		esac
	done
}

config_unit_all(){
	# config all unit enable or disable
	config_unit_config "ALL" "$temp3" unit_enable_all unit_disable_all
}

config_unit_tx2i(){
	# config tx2i unit enable or disable
	config_unit_config "TX2i" "$temp4" unit_tx2i_enable unit_tx2i_disable
}

config_unit_net(){
	# config net unit enable or disable
	config_unit_config "Net" "$temp5" unit_net_enable unit_net_disable
}

config_unit_apu(){
	# config net unit enable or disable
	config_unit_config "Apu" "$temp6" unit_apu_enable unit_apu_disable
}

config_unit_cdu(){
	# config cdu unit enable or disable
	config_unit_config "Cdu" "$temp7" unit_cdu_enable unit_cdu_disable
}

config_unit_ioin(){
	# config ioin unit enable or disable
	config_unit_config "Ioin" "$temp8" unit_ioin_enable unit_ioin_disable
}

config_unit_ioout(){
	# config ioout unit enable or disable
	config_unit_config "Ioout" "$temp9" unit_ioout_enable unit_ioout_disable
}

config_unit_dgps(){
	# config dgps unit enable or disable
	config_unit_config "Dgps" "$temp10" unit_dgps_enable unit_dgps_disable
}

config_unit_bb(){
	# config blackbox unit enable or disable
	config_unit_config "Bbox" "$temp11" unit_bb_enable unit_bb_disable
}

config_unit_ota(){
	# config ota unit enable or disable
	config_unit_config "Ota" "$temp12" unit_ota_enable unit_ota_disable
}

config_unit_power(){
	# config power switch unit enable or disable
	config_unit_config "Power" "$temp13" unit_power_enable unit_power_disable
}

verification_config(){
	# change config parameter
	while true
	do
		whiptail --clear --fb\
		--title "GG3.1 SYSTEM AUTO TEST"\
		--backtitle "  UISEE DRIVER IDU SYSTEM"\
		--menu "\n\n\n  GG3.1 system auto test\n\n\
		Copyright   :    Embedded system testing\n\
		Version     :    V4.0.0\n\
		Date        :    $(date "+%F %T %p")\n\
		Infomation  :    The GG31 system performance verification test covers the test cases that can be involved in the master and slave sides !\n\n\n"\
		35 95 13 A "_ CONFIG  :    Module    Config    View"\
		B "_ CONFIG  :    Module    Uos     Switch"\
		C "_ CONFIG  :    Module    ALL     Switch"\
		D "_ CONFIG  :    Module    TX2i    Switch"\
		E "_ CONFIG  :    Module    Net     Switch"\
		F "_ CONFIG  :    Module    Apu     Switch"\
		G "_ CONFIG  :    Module    Cdu     Switch"\
		H "_ CONFIG  :    Module    Ioin    Switch"\
		I "_ CONFIG  :    Module    Ioout   Switch"\
		J "_ CONFIG  :    Module    Dgps    Switch"\
		K "_ CONFIG  :    Module    Bbox    Switch"\
		L "_ CONFIG  :    Module    Ota     Switch"\
		M "_ CONFIG  :    Module    Power   Switch" 2> $temp1
		selection=$(cat $temp1)
		case $selection in
			A)
			config_doc_view;;
			B)
			config_unit_uos;;
			C)
			config_unit_all;;
			D)
			config_unit_tx2i;;
			E)
			config_unit_net;;
			F)
			config_unit_apu;;
			G)
			config_unit_cdu;;
			H)
			config_unit_ioin;;
			I)
			config_unit_ioout;;
			J)
			config_unit_dgps;;
			K)
			config_unit_bb;;
			L)
			config_unit_ota;;
			M)
			config_unit_power;;
			*)
			first_interface;;
		esac
	done
}

verification_module(){
	# gg3.1 system per module test
	while true
	do
		whiptail --clear --fb\
		--title "GG3.1 SYSTEM AUTO TEST"\
		--backtitle "  UISEE DRIVER IDU SYSTEM"\
		--menu "\n\n\n  GG3.1 system auto test\n\n\
		Copyright   :    Embedded system testing\n\
		Version     :    V4.0.0\n\
		Date        :    $(date "+%F %T %p")\n\
		Infomation  :    The GG31 system performance verification test covers the test cases that can be involved in the master and slave sides !\n\n\n"\
		35 95 11 A "_ UNIT  :    Module    TX2i    Test"\
		B "_ UNIT  :    Module    Net     Test"\
		C "_ UNIT  :    Module    Apu     Test"\
		D "_ UNIT  :    Module    Cdu     Test"\
		E "_ UNIT  :    Module    Ioin    Test"\
		F "_ UNIT  :    Module    Ioout   Test"\
		G "_ UNIT  :    Module    Dgps    Test"\
		H "_ UNIT  :    Module    Ota     Test"\
		I "_ UNIT  :    Module    Power   Test"\
		J "_ UNIT  :    Module    Bbox    Test"\
		K "_ UNIT  :    Module    All     Test" 2> $temp2
		selection=$(cat $temp2)
		case $selection in
			A)
			get_gg_test "check_tx2i";;
			B)
			get_gg_test "check_net";;
			C)
			get_gg_test "check_apu";;
			D)
			get_gg_test "check_cdu";;
			E)
			get_gg_test "check_ioin";;
			F)
			get_gg_test "check_ioout";;
			G)
			get_gg_test "check_dgps";;
			H)
			get_gg_test "check_ota";;
			I)
			get_gg_test "check_power";;
			J)
			get_gg_test "check_bb";;
			K)
			get_gg_test "check_all";;
			*)
			first_interface ;;
		esac
	done
}

verification_log(){
	# check excute log
	get_window_size
	get_filename=$(zenity --title "UISEE System Test : Select Log File" --file-selection --save)
	whiptail --clear --fb\
	--title="Select Log File ( \"Esc\" to quit )"\
	--backtitle "  UISEE DRIVER IDU SYSTEM"\
	--textbox --scrolltext $get_filename $box_height $box_width
}

verification_readme(){
	# help document
	get_window_size
	get_filename=/home/worker/GG31/README.md
	whiptail --clear --fb\
	--title="Help Document ( \"Esc\" to quit )"\
	--backtitle "  UISEE DRIVER IDU SYSTEM"\
	--textbox --scrolltext $get_filename $box_height $box_width
}

first_interface(){
	# main menu : first interface
	local hwaddr=$(ifconfig eth0 |grep -i HWaddr |awk '{print $5}')
	config_unit_mktemp
	while true
	do
		whiptail --clear --fb\
		--title "GG3.1 SYSTEM AUTO TEST"\
		--backtitle "  UISEE DRIVER IDU SYSTEM"\
		--menu "\n\n\n  GG3.1 system auto test\n\n\
		Copyright   :    Embedded system testing\n\
		Version     :    V4.0.0\n\
		Date        :    $(date "+%F %T %p")\n\
		Mac_address :    ${hwaddr}\n\
		Infomation  :    The GG31 system performance verification test covers the test cases that can be involved in the master and slave sides !\n\n\n"\
		30 90 4 1 "_ CHECK    :    Verification Config"\
		2 "_ CHECK    :    Verification Module"\
		3 "_ CHECK    :    Verification Runlog"\
		4 "_ CHECK    :    Verification Readme" 2> $temp0
		selection=$(cat $temp0)
		case $selection in
			1)
			verification_config;;
			2)
			verification_module;;
			3)
			verification_log;;
			4)
			verification_readme;;
			*)
			whiptail --clear --fb\
			--title "Exit System"\
			--backtitle "  UISEE DRIVER IDU SYSTEM"\
			--msgbox "\n    Exit the current system\n\n    $(date "+%F %T %p")" 15 48
			exit 1 ;;
		esac
	done
}

first_interface
