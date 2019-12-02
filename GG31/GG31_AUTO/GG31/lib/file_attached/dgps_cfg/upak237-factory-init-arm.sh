#!/bin/bash

usage() {
    base=`basename $0`
    echo "Usage: $base [options] Port1"
    echo "Port1 is serial port connecting to UPak237 board"
    echo ""
    echo "      -h      help"
    echo "      .       shortcut for Port1=/dev/ttyTHS3"
    exit
}

[ $# == 0 ] && usage

port1=
port2=
nport=0
while [ $# != 0 ]; do
    case "$1" in
        -h)     usage;;
        .)      port1=/dev/ttyTHS3; port2=/dev/ttyTHS1; nport=2;;
        *)      if [ $nport = 0 ]; then
                    port1=$1;
                elif [ $nport = 1 ]; then
                    port2=$1;
                else
                    echo "ERROR: too many ports"
                    usage
                fi
                ((nport ++));;
    esac
    shift
done

if [ $nport != 2 ]; then
    echo "ERROR: two ports are needed"
    usage
fi

if [ -x ./vstream-write ]; then
    BIN=./vstream-write
elif [ -x bin/vstream-write ]; then
    BIN=bin/vstream-write
else
    echo "ERROR: vstream-write is missing"
fi

DIR=`dirname $0`
echo "Programming via $port1 at baudrate=19200bps ..."
sudo $BIN -b 19200  ${port1} < ${DIR}/upak237-factory-init-cmda.txt
sleep 1
echo "Programming via $port1 at baudrate=115200bps ..."
sudo $BIN -b 115200 ${port1} < ${DIR}/upak237-factory-init-cmda.txt

