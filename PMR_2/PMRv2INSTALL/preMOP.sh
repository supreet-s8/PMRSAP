#!/bin/bash

IPS="$PWD/IP.sh"
function getHosts()
{
  source ${IPS}
  if [[ $? -ne 0 ]]
  then
    printf "Unable to read source for IP Address List\nCannot continue"
    exit 255
  fi
}
# Get Hosts
getHosts

SSH='ssh -q -o StrictHostKeyChecking=no -o ConnectTimeout=5 -o UserKnownHostsFile=/dev/null -l root ';
clear
echo "------- CHECKING BUILD VERSION -----------"
#for i in $cnp $cmp $ccp $sgp $uip
for i in $cnp $sgp $mgmt
do
  echo -n "Version on ${prefix}${i}   "
  $SSH ${prefix}${i} "/opt/tms/bin/cli -t 'en' 'show ver' " | grep "Build ID" || echo ""
done

read -p "Continue (y): "
[ "$REPLY" != "y" ] && exit 0 
clear
echo "------- CHECKING HDFS STATUS -----------"
$SSH ${prefix}${cnp0} "/opt/hadoop/bin/hadoop dfsadmin -report" | head -12

read -p "Continue (y): "
[ "$REPLY" != "y" ] && exit 0 
clear
echo "------- CHECKING HADDOP PROCESS STATUS -----------"
$SSH ${prefix}${cnp0} "ps -ef " | grep java | egrep -i "datanode|namenode|Bootstrap|jobtracker" | awk '{ print $9 }'

read -p "Continue (y): "
[ "$REPLY" != "y" ] && exit 0 
clear
echo "------- CHECKING INSTA STATUS -----------"
$SSH ${prefix}${ccp0} "/usr/local/Calpont/bin/calpontConsole getsysteminfo"

read -p "Continue (y): "
[ "$REPLY" != "y" ] && exit 0 
clear
echo "------- CHECKING INCOMING DATA STATE -----------"
myda=`date "+%d"`;mymo=`date "+%m"`;myyr=`date "+%Y"`;myti=`date "+%T" | awk -F: '{print $1}'`;echo;echo "Check good size current files "`TZ=America/Los_Angeles date "+%m/%d/%y %H:%M  %Z"`;echo;for j in $dclist; do for i in ipfix SubscriberIB pilotPacket; do hadoop dfs -lsr /data/$j/$i/$myyr/$mymo/ 2>/dev/null | tail -5; done;done

#myda=`date "+%d"`;mymo=`date "+%m"`;myyr=`date "+%Y"`;myti=`date "+%T" | awk -F: '{print $1}'`;echo;echo "Check good size current files "`TZ=America/Los_Angeles date "+%m/%d/%y %H:%M  %Z"`;echo;for j in $dclist; do for i in ipfix SubscriberIB pilotPacket; do hadoop dfs -lsr /data/$j/$i/$myyr/$mymo/ 2>/dev/null|awk '{if ($5 > 100000) print $0}'|tail -1; done;done|awk '{print $5 $8}' | awk -F "/" -v  t1=$myti '{print $1", " $3","$4","$7","t1-$8}' | awk -F "," -v d1=$myda '{if (d1!=$4) print $1", "$2", "$3", Not Current";else if ($5 >=2 && d1=$4) print $1", "$2","$3", "$5" hours late";else if ($5<=1 && $5 >= 0 && d1=$4) print $1", "$2", "$3", Current"}';

read -p "Continue (y): "
[ "$REPLY" != "y" ] && exit 0 
clear

echo "------- CHECKING DRBD STATE ---------"
echo "Namenodes"
for i in $cnp ; do
  $SSH ${prefix}${i} "drbd-overview"
done
echo "Service Gateways"
for i in $sgp1 ; do
  $SSH ${prefix}${i} "drbd-overview"
done
echo "UI Nodes"
for i in $uip ; do
  $SSH ${prefix}${i} "drbd-overview"
done

read -p "Continue (y): "
[ "$REPLY" != "y" ] && exit 0
clear


echo "----- VERIFY TOMCAT PIDs -----"
for i in $uip ; do
  echo "Working on Node : ${prefix}${i}"
  echo "QE PID : `$SSH ${prefix}${i} 'ps -ef | grep qecache | grep -v grep' | awk '{ print $2 }'`"
  echo "RGE PID : `$SSH ${prefix}${i} 'ps -ef | grep rge | grep -v grep' | awk '{ print $2 }'`"
  echo ""
done
read -p "Continue (y): "
[ "$REPLY" != "y" ] && exit 0
clear

echo "------- VERIFYING JOBS ---------"

echo " ---- Verifying on Master Namenode ---- "
for i in $cnp0 ; do
  echo -n "Currently RUNNING Jobs :  "
  $SSH ${prefix}${i} '/opt/tps/bin/pmx.py subshell oozie show coordinator RUNNING jobs' | awk '{ print $2 }' | grep -v ID | grep -v Jobs | grep -v "^$" | sort | wc -l
  echo -n "Currently PREP Jobs    :  "
  $SSH ${prefix}${i} '/opt/tps/bin/pmx.py subshell oozie show coordinator PREP jobs' | awk '{ print $2 }' | grep -v ID | grep -v Jobs | grep -v "^$" | sort | wc -l
done
echo ""
echo " ---- Verifying on Master SG Node ---- "
for i in $sgp0 ; do
  echo -n "Currently RUNNING Jobs :  "
  $SSH ${prefix}${i} '/opt/tps/bin/pmx.py subshell oozie show coordinator RUNNING jobs' | awk '{ print $2 }' | grep -v ID | grep -v Jobs | grep -v "^$" | sort | wc -l
  echo -n "Currently PREP Jobs    :  "
  $SSH ${prefix}${i} '/opt/tps/bin/pmx.py subshell oozie show coordinator PREP jobs' | awk '{ print $2 }' | grep -v ID | grep -v Jobs | grep -v "^$" | sort | wc -l
done

read -p "Continue (y): "
[ "$REPLY" != "y" ] && exit 0
clear
