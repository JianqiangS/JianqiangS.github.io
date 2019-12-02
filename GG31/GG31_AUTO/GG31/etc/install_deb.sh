#!/bin/bash
SOURCE_PATH=/home/worker/GG31
source ${SOURCE_PATH}/etc/common.sh

install_deb_check(){
	# judge deb package is installed
	which $1 > ${C_D_NULL}
	if [ "$?" -ne 0 ]
	then
		$2
	fi
}

install_deb_csvkit(){
	# install csvkit deb package
	echo "start install csvkit package"
	sudo dpkg -i ${R_P_LIB_DEB}/deb_csvkit/python3-dateutil_2.4.2-1_all_0.deb
	sudo dpkg -i ${R_P_LIB_DEB}/deb_csvkit/python3-jdcal_1.0-1build1_all_1.deb
	sudo dpkg -i ${R_P_LIB_DEB}/deb_csvkit/python3-openpyxl_2.3.0-1_all_2.deb
	sudo dpkg -i ${R_P_LIB_DEB}/deb_csvkit/python3-sqlalchemy_1.0.11+ds1-1ubuntu2_all_3.deb
	sudo dpkg -i ${R_P_LIB_DEB}/deb_csvkit/python3-xlrd_0.9.4-1_all_4.deb
	sudo dpkg -i ${R_P_LIB_DEB}/deb_csvkit/python3-csvkit_0.9.1-2_all_5.deb
	sudo dpkg -i ${R_P_LIB_DEB}/deb_csvkit/python3-pil_3.1.2-0ubuntu1.1_arm64_6.deb
	sudo dpkg -i ${R_P_LIB_DEB}/deb_csvkit/python3-py_1.4.31-1_all_7.deb
	sudo dpkg -i ${R_P_LIB_DEB}/deb_csvkit/python3-pytest_2.8.7-4_all_8.deb
}

install_deb_expect(){
	# install expect deb package
	echo "start install expect package"
	sudo dpkg -i ${R_P_LIB_DEB}/deb_expect/tcl-expect_5.45-7_arm64.deb
	sudo dpkg -i ${R_P_LIB_DEB}/deb_expect/expect_5.45-7_arm64.deb
}

install_deb_ffmpeg(){
	# install ffmpeg deb package
	echo "start install ffmpeg(ffplay) package"
	sudo dpkg -i ${R_P_LIB_DEB}/deb_ffmpeg/libavresample-ffmpeg2_7%3a2.8.15-0ubuntu0.16.04.1_arm64_0.deb
	sudo dpkg -i ${R_P_LIB_DEB}/deb_ffmpeg/libflite1_2.0.0-release-1_arm64_1.deb
	sudo dpkg -i ${R_P_LIB_DEB}/deb_ffmpeg/libsodium18_1.0.8-5_arm64_2.deb
	sudo dpkg -i ${R_P_LIB_DEB}/deb_ffmpeg/libzmq5_4.1.4-7_arm64_3.deb
	sudo dpkg -i ${R_P_LIB_DEB}/deb_ffmpeg/libavfilter-ffmpeg5_7%3a2.8.15-0ubuntu0.16.04.1_arm64_4.deb
	sudo dpkg -i ${R_P_LIB_DEB}/deb_ffmpeg/libavdevice-ffmpeg56_7%3a2.8.15-0ubuntu0.16.04.1_arm64_5.deb
	sudo dpkg -i ${R_P_LIB_DEB}/deb_ffmpeg/ffmpeg_7%3a2.8.15-0ubuntu0.16.04.1_arm64_6.deb
}

install_deb_firefox(){
	# install firefox deb package
	echo "start install firefox package"
	sudo dpkg -i ${R_P_LIB_DEB}/deb_firefox/firefox_70.0+build2-0ubuntu0.16.04.1_arm64.deb
}

install_deb_gnuplot(){
	# install gnuplot deb package
	echo "start install gnuplot package"
	sudo dpkg -i ${R_P_LIB_DEB}/deb_gnuplot/aglfn_1.7-3_all.deb
	sudo dpkg -i ${R_P_LIB_DEB}/deb_gnuplot/gnuplot-tex_4.6.6-3_all.deb
	sudo dpkg -i ${R_P_LIB_DEB}/deb_gnuplot/gnuplot5-data_5.0.3+dfsg2-1_all.deb
	sudo dpkg -i ${R_P_LIB_DEB}/deb_gnuplot/liblua5.1-0_5.1.5-8ubuntu1_arm64.deb
	sudo dpkg -i ${R_P_LIB_DEB}/deb_gnuplot/libwxbase3.0-0v5_3.0.2+dfsg-1.3ubuntu0.1_arm64.deb
	sudo dpkg -i ${R_P_LIB_DEB}/deb_gnuplot/libwxgtk3.0-0v5_3.0.2+dfsg-1.3ubuntu0.1_arm64.deb
	sudo dpkg -i ${R_P_LIB_DEB}/deb_gnuplot/gnuplot5-qt_5.0.3+dfsg2-1_arm64.deb
	sudo dpkg -i ${R_P_LIB_DEB}/deb_gnuplot/gnuplot_4.6.6-3_all.deb
}

install_deb_hdparm(){
	# install hdparm deb package
	echo "start install hdparm package"
	sudo dpkg -i ${R_P_LIB_DEB}/deb_hdparm/hdparm_9.48+ds-1ubuntu0.1_arm64.deb
	sudo dpkg -i ${R_P_LIB_DEB}/deb_hdparm/wermgmt-base_1.31+nmu1_all.deb
}

install_deb_heirloom_mailx(){
	# install heirloom-mailx deb package
	echo "start install heirloom-mailx package"
	sudo dpkg -i ${R_P_LIB_DEB}/deb_heirloom-mailx/s-nail_14.8.6-1_arm64.deb
	sudo dpkg -i ${R_P_LIB_DEB}/deb_heirloom-mailx/heirloom-mailx_14.8.6-1_all.deb
	sudo cp ${R_P_LIB_DEB}/deb_heirloom-mailx/s-nail.rc /etc/
}

install_deb_uuencode(){
	# install uuencode deb package
	echo "start install uuencode package"
	sudo dpkg -i ${R_P_LIB_DEB}/deb_uuencode/sharutils_1%3a4.15.2-1ubuntu0.1_arm64.deb
}
