#!/bin/bash
#
# Ubiquiti UCK-G2 Display update script
# Origin:
# https://bitbucket.org/dskillin/cloudkey-g2-display/src/main/fbshow
#
# Install sysstat package before use.

MYFONT=Helvetica
FIXED=DejaVu-Sans-Mono
NARROW=Helvetica-Narrow
FXSIZE=14
FNAME=$(mktemp --suff=.png)
ORDER=1

update_sysstat() {
    if [ $ORDER -eq 1 ]; then
        MYIP=$(ip -4 addr show eth0 | grep -oP '(?<=inet\s)\d+(\.\d+){3}')
        ORDER=0
    else
        MYIP=$(hostname -s)
        ORDER=1
    fi
    CPUPERCENT=$(mpstat | awk '$12 ~ /[0-9.]+/ { print 100 - $12"%" }')
    MEMPERCENT=$(free -m | awk 'NR==2{printf "%.1f%%\n", $3*100/$2 }')
}

draw_sysstat() {
    TSTR=`date "+%H:%M:%S %Z"`
    #
    convert -size 128x64 xc:black \
        -gravity north -undercolor black -fill white -font "$FIXED" -pointsize $FXSIZE -annotate +0+5 "$MYIP" \
        -gravity south -undercolor black -fill white -font $MYFONT -pointsize 20 -annotate +0+18 "$TSTR" \
        -gravity south -undercolor black -fill white -font $NARROW -pointsize 11 -annotate +0+5 \
        "CPU: $CPUPERCENT  MEM: $MEMPERCENT" $FNAME
    #
    ck-splash -s image -f $FNAME >/dev/null
}

cleanup() {
    rm -f "$FNAME"
}

if [ "$1" = "once" ]; then
    #
    # run once then exit
    #
    update_sysstat
    draw_sysstat
    cleanup
    exit
fi

#
# 1-second timer subshell for time update
#
{
    while :; do
        sleep 1
        kill -USR1 $$
    done
} &

#
# 4-second timer subshell for sysstat update
#
{
    while :; do
        sleep 4
        kill -USR2 $$
    done
} &

update_sysstat
trap draw_sysstat USR1
trap update_sysstat USR2
trap cleanup TERM

#
# event loop
#
while :; do
    sleep .1
done

