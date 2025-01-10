#!/usr/bin/env bash

# ZABBIX DATABASE FULL BACKUP
# Author: diasdm
# This script creates a full backup of the Zabbix database using mysqldump, 
# compresses it with gzip, and logs the process.

# REQUIREMENTS:
#     - mysqldump
#     - gzip

# USAGE:
#     To use a pre-set Zabbix DB authentication,
#     set values below (#002.001) and pass the "-d" argument.
#         ./zabbix_db_bkp_full.sh -d

#     To use your Zabbix DB authentication as arguments,
#     pass all arguments in the order below.
#         ./zabbix_db_bkp_full.sh "[dbhost]" "[dbname]" "[dbuser]" "[dbpass]"
#     PS: THE DUMP MAY FAIL IF ANY ARGUMENT IS OUT OF ORDER


#001 REQUIREMENTS CHECK
if ! which mysqldump > /dev/null; then
    echo "Error: mysqldump binary was not found."
    exit 1
elif ! which gzip > /dev/null; then
    echo "Error: gzip binary was not found."
    exit 1
fi


#002 VAR
bkpdir=${HOME}/zabbix_db_bkp   # BACKUP LOCAL DIR
bkplogdir=${bkpdir}/log        # BACKUP LOG DIR
bkpname=zabbix_db_bkp_full     # BACKUP FILE NAME
bkpdays=30                     # NUMBER OF DAYS TO KEEP OLD BACKUP

TIME=$(date +%Y%m%d%H%M%S)     # BACKUP FILE TIMESTAMP

#002.001 VAR TEST
if [[ "$*" = "-d" ]]; then
    dbhost="localhost"         # SET HERE YOUR DEFAULT DB HOSTNAME
    dbname="zabbix"            # SET HERE YOUR DEFAULT DB NAME
    dbuser="zabbix"            # SET HERE YOUR DEFAULT DB USERNAME
    dbpass="zabbix"            # SET HERE YOUR DEFAULT DB USERNAME'S PASSWORD
else
    if [[ -z "$1" ]]; then echo -e "\nDB HOST MISSING - ARG 1\n"; exit 2; fi
    dbhost="$1"
    if [[ -z "$2" ]]; then echo -e "\nDB NAME MISSING - ARG 2\n"; exit 2; fi
    dbname="$2"
    if [[ -z "$3" ]]; then echo -e "\nDB USER MISSING - ARG 3\n"; exit 2; fi
    dbuser="$3"
    if [[ -z "$4" ]]; then echo -e "\nDB PASSWORD MISSING - ARG 4\n"; exit 2; fi
    dbpass="$4"
fi


#003 LOG WRITE
# Logs messages to both console and log file.
function log_write {
    local logtime
    logtime=$(date +%Y%m%d%H%M%S)
    echo "${logtime} >> $1"
    echo "${logtime} >> $1" >> "${bkplogdir}/${bkpname}.log"
}


#004 BACKUP DIR CREATION
[[ ! -d "${bkpdir}" ]] && mkdir -v "${bkpdir}"
[[ ! -d "${bkplogdir}" ]] && mkdir -v "${bkplogdir}"


#005 LOG START MESSAGE
clear
echo ""

STARTTIME=$(date +%s)

log_write "------------------------------------------------"
log_write "START"


#006 MYSQL FULL DUMP
log_write "Dumping \"${dbname}\" database"

if mysqldump -h"${dbhost}" -u"${dbuser}" -p"${dbpass}" \
    --flush-logs \
    --single-transaction \
    --create-options \
    "${dbname}" | gzip > "${bkpdir}/${TIME}_${bkpname}.sql.gz";then

    DUMPSTATUS=0
    log_write "DB dump complete. File \"${bkpdir}/${TIME}_${bkpname}.sql.gz\""
else
    DUMPSTATUS=1
    log_write "## DB dump failed ##"
    exit 5
fi


#007 CLEAN UP OLD BACKUP
# Stats may be pulled from Zabbix
log_write "Excluding old backup with more than ${bkpdays} days"

find "${bkpdir}"/* -mtime +${bkpdays} -exec rm -f {} +


#008 LOG BACKUP TIME TAKEN AND FILE SIZE
BKPBYTES=$(stat --printf="%s" "${bkpdir}/${TIME}_${bkpname}.sql.gz")
BKPMEGAS=$(( BKPBYTES / 1024 ** 2 ))

ENDTIME=$(date +%s)
TOTALSEC=$(( ENDTIME - STARTTIME ))
TOTALTIME=$(date -d@"$TOTALSEC" -u +%Hh%Mm%Ss)

log_write "Backup file size: ${BKPBYTES}B - ${BKPMEGAS}MB"
log_write "Backup total time: ${TOTALSEC}s - $TOTALTIME"
log_write "Backup stats: {\"dump_status\":${DUMPSTATUS},\"size\":${BKPBYTES},\"time\":${TOTALSEC}}"

log_write "FINISH"
exit 0