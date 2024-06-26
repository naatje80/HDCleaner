#! /bin/bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
DISK=${1}

if [[ `id -u` -ne 0 ]]
then
	echo "ERROR: This script requires root privileges!"
	exit 1
fi

if [[ ! -b ${DISK} ]]
then
	echo "ERROR: Drive ${DISK} does not exist!"
	exit 1
fi

# Get Disk serial number
SERIAL=`hdparm -I ${DISK}|grep "Serial Number"|tr -d ' '|cut -d: -f2`

# Get expected duration for secure erase
EXPECTED_DURATION=`hdparm -I ${DISK}|grep "for SECURITY ERASE UNIT"|sed 's/min/:/'|cut -d: -f 1`

# Check if disk is frozen
NOT_FROZEN=`hdparm -I ${DISK}|grep "not[[:space:]]frozen"`

# Uncomment for debugging
#echo "DEBUG: FROZEN STATE: \"${NOT_FROZEN}\"; SERIAL: ${SERIAL}; EXPECTED DURATION: ${EXPECTED_DURATION}"

if [[ -z ${NOT_FROZEN} ]]
then
	echo ""
	echo "!!!IMPORTANT!!! Drive needs to be \"unfronzen\". This system will be temporary suspended. Wait a couple of seconds, and manually start your system by pressing the power button."
	echo "Please ensure all your data is saved. (Press [Ctrl]+[C] to cancel)"
	read -p "Press any key to continue..." INPUT
	echo -n "mem" > /sys/power/state
else
	echo "Disk is not frozen, we should be able to proceed..."
fi

# Check if disk is no longer frozen
NOT_FROZEN=`hdparm -I ${DISK}|grep "not[[:space:]]frozen"`
if [[ -z ${NOT_FROZEN} ]]
then
	echo "ERROR: Unable to unfreeze the disk. Exiting..."
	exit 1
fi

INPUT="BOGUS"
while [[ ${SERIAL} != ${INPUT} ]]
do
	echo ""
	echo "!!!VERRY VERRY IMPORTANT!!!: The disk will now be securly erased. All data will be permanently lost!!!!"
	echo "Press [Ctrl]+[C] to discontinue!"
	read -p "Provide the the serial number for the disk to continue (${SERIAL}): " INPUT
done

# Ensure that none of the partions on the disks are mounted
for PARTITION in `cat /etc/mtab|grep ${DISK}|tr -s ' '|cut -d ' ' -f 1`
do
	umount -f ${PARTITION}
done

hdparm --user-master u --security-set-pass MyVerrySecretPassword ${DISK} >/dev/null 2>&1
${SCRIPT_DIR}/progress_bar.sh $(( ${EXPECTED_DURATION} * 60 )) 70 "Secure erasing disk (est. duration ${EXPECTED_DURATION} min.): ${DISK}" &
PPN_PROGRESS=$!
hdparm --user-master u --security-erase-enhanced MyVerrySecretPassword ${DISK} >/dev/null 2>&1
kill ${PN_PROGRESS}
partprobe ${DISK}
