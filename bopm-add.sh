#!/bin/bash
# bopm-add.sh
# Extracts positive scan hits from BOPM (Blitzed Open Proxy Monitor) and adds them to the GTAXLnet DNSBL
# Victor Coss gtaxl@gtaxl.net
# Version 1.00 AUG/20/2020

logdir=/home/gtaxl/bopm/var
scriptdir=/home/gtaxl/dnsbl/

echo "" > $logdir/bopm.log
tail -f $logdir/bopm.log | grep --line-buffered "OPEN PROXY" | while read do a b c d e f g h ip reason j; do
$scriptdir/gnbl.sh add ${ip%:*} Open Proxy, $reason [PScan] >> $logdir/dnsbl.log 2>&1 &
done
