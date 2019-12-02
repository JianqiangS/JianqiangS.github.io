#!/bin/bash

if [ -x ./vstream-write ]; then
    BIN=./vstream-write
elif [ -x bin/vstream-write ]; then
    BIN=bin/vstream-write
else
    echo "ERROR: vstream-write is missing"
    exit 1
fi

echo "$0 verstion is 0.1"
sudo killall rtkproc.lnxarm

DIR=`dirname $0`
# comment $jasc,gga,1 to disable ttyTHS3 output
port1=/dev/ttyTHS3
echo "Programming via $port1 at baudrate=19200bps ..."
sudo $BIN -b 19200  ${port1} < ${DIR}/ttyTHS3.txt
sleep 1
echo "Programming via $port1 at baudrate=115200bps ..."
sudo $BIN -b 115200 ${port1} < ${DIR}/ttyTHS3.txt

port1=/dev/ttyTHS1
echo "Programming via $port1 at baudrate=19200bps ..."
sudo $BIN -b 19200  ${port1} < ${DIR}/ttyTHS1.txt
sleep 1
echo "Programming via $port1 at baudrate=115200bps ..."
sudo $BIN -b 115200 ${port1} < ${DIR}/ttyTHS1.txt

echo "Please do reboot!"


