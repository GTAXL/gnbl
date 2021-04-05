#!/bin/bash
# bopm-add.sh
# Extracts positive scan hits from HOPM (Hybrid Open Proxy Monitor) and adds them to the GTAXLnet DNSBL
# Victor Coss gtaxl@gtaxl.net
# Version 1.00 APR/04/2021

logdir=/home/gtaxl/hopm/var/log
scriptdir=/home/gtaxl/dnsbl/

echo "" > $logdir/hopm.log
tail -f $logdir/hopm.log | grep --line-buffered "OPEN PROXY" | while read do a b c d e ip reason j; do
$scriptdir/gnbl.sh add ${ip%:*} Open Proxy, $reason [PScan] >> $logdir/dnsbl.log 2>&1 &
done
