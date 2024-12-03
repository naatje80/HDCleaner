#! /bin/bash

NVME_DEVICES=`nvme list -o json|grep 'DevicePath'|tr -d ' '|tr -d '"'|cut -d: -f 2`
IFS=', ' read -r -a array <<< ${NVME_DEVICES}

SERIALNUMBER=`nvme id-ctrl ${1}|tr -d ' '|grep 'sn:'|cut -d: -f2`

# Do not use "Overwrite Erase" to save life endurance of NVME
# Thefore this option is not verified
SAN_BE_SUPPORTED=`nvme id-ctrl ${1} -H|grep 'Block Erase Sanitize Operation'|grep -c '0x1'`
SAN_CE_SUPPORTED=`nvme id-ctrl ${1} -H|grep 'Crypto Erase Sanitize Operation'|grep -c '0x1'`
FORM_CE_SUPPORTED=`nvme id-ctrl ${1} -H|grep 'Crypto Erase'|grep 'Secure Erase'|grep -c '0x1'`

# Uncomment for debug
#echo -e "DEBUG:--->\nSanitize Block Erase: ${SAN_BE_SUPPORTED}\nSantize Crypto Erase: ${SAN_CE_SUPPORTED}\nFormat Secure Erase: ${FORM_CE_SUPPORTED}"

if [[ ${SAN_CE_SUPPORTED} -eq 1 ]]
then
	ERASE_COMMAND="nvme sanitze ${1} -a start-crypto-erase"
	DURATION=`nvme sanitize-log ${1}|grep 'Estimated Time For Crypto Erase'|tr -d ' '|cut -d: -f2`
elif [[ ${SA_BE_SUPPORTED} -eq 1 ]]
then
	ERASE_COMMAND="nvme sanitze ${1} -a start-block-erase"
	DURATION=`nvme sanitize-log ${1}|grep 'Estimated Time For Block Erase'|tr -d ' '|cut -d: -f2`
elif [[ ${FORM_CE_SUPPORTED} -eq 1 ]]
then
	if [[ `nvme id-ctrl ${1} -H|grep -E 'Format Applies to Single Namespace\(s\)|Crypto Erase Applies to Single Namespace\(s\)'|grep -c -v '0x1'` -eq 1 ]]
	then
		ERASE_COMMAND="nvme format ${1} -s 2 -n 1"
	fi
else
	ERASE_COMMAND="blkdiscard --secure ${1} -f|blkdiskcard --zeroout /${1} -f"
fi

${ERASE_COMMAND}
