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
L1SZ=14
L2SZ=18
L3SZ=11
FNAME=$(mktemp --suff=.png)
ORDER=0
ABTIMER=60
PXSTEP=15
DISPMODE=1
IP_FONTSZ=76
HS_FONTSZ=72
UP_FONTSZ=56
NR_FONTSZ=48
IP_IMGLEN=1125
UP_IMGLEN=1125
NR_IMGLEN=1125
HS_IMGLEN=1140

s2dhms() {
    ((d=${1}/(60*60*24)))
    ((h=(${1}%(60*60*24))/(60*60)))
    ((m=(${1}%(60*60))/60))
    UPSTR=`printf "%dd %02dh%02dm" $d $h $m`
}

update_sysstat() {
    case $ORDER in
        0)
            MYIP=$(ip -4 addr show eth0 | grep -oP '(?<=inet\s)\d+(\.\d+){3}')
            MYHNAME=$(hostname -s)
            DISPSTR=$MYHNAME
            ORDER=1
            ;;
        1)
            DISPSTR=$MYHNAME
            MYIP=$(ip -4 addr show eth0 | grep -oP '(?<=inet\s)\d+(\.\d+){3}')
            [[ -n $MYIP ]] && DISPSTR=$MYIP
            ORDER=2
            ;;
        2)
            MYHNAME=$(hostname -s)
            DISPSTR=$MYHNAME
            ORDER=3
            ;;
        *)
            UPTS=`cut -d ' ' -f 1 /proc/uptime|cut -d '.' -f1`
            s2dhms $UPTS
            DISPSTR="up: $UPSTR"
            ORDER=1
            ;;
    esac
    CPUPERCENT=$(mpstat | awk '$12 ~ /[0-9.]+/ { print 100 - $12"%" }')
    MEMPERCENT=$(free -m | awk 'NR==2{printf "%.1f%%\n", $3*100/$2 }')
}

draw_sysstat() {
    # display if no anti burn-in
    if [[ $DISPMODE -eq 1 ]]; then
        TSTR=`date "+%H:%M:%S %Z"`
        #
        convert -size 128x64 xc:black \
            -gravity north -undercolor black -fill white -font "$FIXED" -pointsize $L1SZ -annotate +0+5 "$DISPSTR" \
            -gravity south -undercolor black -fill white -font $MYFONT -pointsize $L2SZ -annotate +0+18 "$TSTR" \
            -gravity south -undercolor black -fill white -font $NARROW -pointsize $L3SZ -annotate +0+5 \
            "CPU: $CPUPERCENT  MEM: $MEMPERCENT" $FNAME
        #
        ck-splash -s image -f $FNAME >/dev/null
    fi
}

banner_str() {
    local TEXT=$1
    local FONT=$2
    local FONTSZ=$3
    local IMGLEN=$4
    local LASTPX=$((IMGLEN - 128))

    convert -size ${IMGLEN}x64 xc:black \
                -gravity center -undercolor black -fill white -font "$FONT" \
                -pointsize $FONTSZ -annotate +0+0 "$TEXT" $FNAME
    for i in `seq 0 $PXSTEP $LASTPX`; do
            convert -crop 128x64+$i+0 $FNAME out.png
            sudo ck-splash -s image -f out.png >/dev/null
    done
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
    # display anti burn-in
    if [[ $(($EPOCHSECONDS % $ABTIMER)) == 0 ]]; then
        DISPMODE=2
        banner_str "IP: $MYIP" "$FIXED" $IP_FONTSZ $IP_IMGLEN
        banner_str "Hostname: $MYHNAME" "$FIXED" $HS_FONTSZ $HS_IMGLEN
        banner_str "Uptime: $UPSTR" "$FIXED" $UP_FONTSZ $UP_IMGLEN
        banner_str "CPU load: $CPUPERCENT, Memory used: $MEMPERCENT" "$NARROW" $NR_FONTSZ $NR_IMGLEN
        #rm -f out.png
        DISPMODE=1
    fi
    sleep .1
done

