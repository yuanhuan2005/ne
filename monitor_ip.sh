#!/bin/bash

if [ $# -ne 1 ]
then
	echo "Usage: $0 IPAddress"
	exit 1
fi

ip_address=$1
log_file=/var/log/monitor.log
ping_count=10
max_avg_delay_ms=50
max_pkg_loss_num=10
every_min=5

tmp_file=`mktemp`
ping -c ${ping_count} ${ip_address} | grep "icmp_seq" | tee ${tmp_file}
if [ `cat ${tmp_file} | wc -l` -eq 0 ]
then
	echo "`date +%Y%m%d%H%M%S` | ${ip_address} is unreachable." >> ${log_file}
	exit 1
fi

# delay time greater than max_avg_delay_ms
avg_delay_float=`cat ${tmp_file} | awk '{print $7}' | awk -F= '{print $2}' | awk '{sum+=$1} END {print sum/NR}'`
avg_delay_int=`echo ${avg_delay_float} | awk -F. '{print $1}'`
if [ ${avg_delay_int} -ge ${max_avg_delay_ms} ]
then
	echo "`date +%Y%m%d%H%M%S` | network delay time to ${ip_address} is greater than ${max_avg_delay_ms}ms in last ${every_min} min." >> ${log_file}
fi

# packet loss number greater than $max_pkg_loss_num
pkg_sent_num=`cat ${tmp_file} | wc -l`
pkg_loss_num=`expr ${ping_count} - ${pkg_sent_num}`
if [ ${pkg_loss_num} -ge ${max_pkg_loss_num} ]
then
	echo "`date +%Y%m%d%H%M%S` | packet loss number to ${ip_address} is greater than ${max_pkg_loss_num} in last ${every_min} min." >> ${log_file}
fi

# clean tmp files
rm -f ${tmp_file}

