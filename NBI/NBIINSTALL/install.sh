#!/bin/bash

#------------------------------------------------------------------------
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

SSH='ssh -q -o ConnectTimeout=5 -o UserKnownHostsFile=/dev/null -l root '
#------------------------------------------------------------------------


DEST="/data/mgmt/pmr/scripts/pm/SAP/"
FILE="pmr-nbi-code-v02.tgz"
SRC="/tmp"

#  MGMT
function restartCron {
echo "---------------------------- Restarting cron service."
for i in $mgmt
do
echo "Working on node: ${prefix}${i}"
sleep 3
$SSH ${prefix}${i} "mount -o remount,rw /"
/usr/bin/scp -q ../restart.cli root@${prefix}${i}:/tmp
$SSH ${prefix}${i} "/opt/tms/bin/cli -x -h /tmp/restart.cli"
done
}

# installNbi into repository.
function installNbi {
echo "---------------------------- Installing NBI code to repository."
for i in $mgmt0
do
echo "Working on node: ${prefix}${i}"
sleep 3
$SSH ${prefix}${i} "mount -o remount,rw /"
$SSH ${prefix}${i} "if [[ ! -e ${DEST}/PMR/etc/PMR_SAP.cron.b4nbi.bkp ]]; then /bin/cp ${DEST}/PMR/etc/PMR_SAP.cron ${DEST}/PMR/etc/PMR_SAP.cron.b4nbi.bkp; fi"
/usr/bin/scp -q ../${FILE} root@${prefix}${i}:${SRC}/
$SSH ${prefix}${i} "/bin/tar zxvf ${SRC}/${FILE} -C ${DEST}/"
done
}

function syncPMR {
echo "---------------------------- Synchronize PMR install with repository."
for i in $mgmt
do
echo "Working on node: ${prefix}${i}"
sleep 3
$SSH ${prefix}${i} "mount -o remount,rw /"
$SSH ${prefix}${i} "/data/scripts/PMR/bin/SyncPMRHosts.sh"
done
}

installNbi
syncPMR
restartCron
echo "---------------------------- Done!"

