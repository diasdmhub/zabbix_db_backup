#!/bin/bash

# ZABBIX DATABASE FULL BACKUP
# SYNTAX: ./zabbix_db_bkp_full.sh "[dbhost]" "[dbuser]" "[dbpass]" "[dbname]"
# PS: THE SCRIPT MIGHT FAIL IF ANY PARAMETER IS OUT OF ORDER
# by diasdm


#001 VAR
        bkpdir=${HOME}/zabbix_db_bkp   # BACKUP LOCAL DIR
        bkplog=${bkpdir}/log           # BACKUP LOG DIR
        bkpname=zabbix_db_bkp_full     # BACKUP FILE NAME
        bkpdays=30                     # NUMBER OF DAYS TO KEEP BACKUP

        TIME=$(date +%Y%m%d%H%M%S)     # BACKUP FILE TIMESTAMP

        [[ -z "$1" ]] && dbhost="localhost" || dbhost="$1"       # DEFAULT DB HOSTNAME/IP
        [[ -z "$2" ]] && dbuser="zabbix" || dbuser="$2"          # DEFAULT DB USERNAME
        [[ -z "$3" ]] && dbpass="zabbix" || dbpass="$3"          # DEFAULT DB USERNAME'S PASSWORD
        [[ -z "$4" ]] && dbname="zabbix" || dbname="$4"          # DEFAULT DB NAME


#002 LOG LEVEL
function log_write {
        logtime=$(date +%Y%m%d%H%M%S)
        echo "${logtime} >> $1" >> ${bkplog}/${bkpname}.log
}


#003 BACKUP DIR CREATION
[ ! -d ${bkpdir} ] && mkdir -v ${bkpdir}
[ ! -d ${bkplog} ] && mkdir -v ${bkplog}


#004 OPTIONAL MESSAGES
        clear

        STARTTIME=$(date +%s)

        echo -e "Backing up config, events, trigger, history etc.\n"

        log_write "------------------------------------------------"
        log_write "START"


#005 MYSQL FULL DUMP
        log_write "Dumping DB config, events, trigger, history etc."

mysqldump -h${dbhost} -u${dbuser} -p${dbpass} \
        --flush-logs \
        --single-transaction \
        --create-options \
        ${dbname} | gzip > ${bkpdir}/${TIME}_${bkpname}.sql.gz

        log_write "DB dump complete"

        BKPBYTES=$(stat --printf="%s" ${bkpdir}/${TIME}_${bkpname}.sql.gz)
        BKPMEGAS=$(( $BKPBYTES / 1024 ** 2 ))

        log_write "Backup file size: ${BKPBYTES}B - ${BKPMEGAS}MB"


#006 CLEAN UP OLD BACKUP
        log_write "Excluding old backup with more than ${bkpdays} days"

        find ${bkpdir}/* -mtime +${bkpdays} -exec rm -f {} \;


#007 LOG BACKUP TIME TAKEN
        ENDTIME=$(date +%s)

        TOTALTIME=$(( $ENDTIME - $STARTTIME ))
        TOTALTIME=$(date -d@"$TOTALTIME" -u +%Hh%Mm%Ss)

        log_write "$TOTALTIME - Backup total time"

        log_write "FINISH"
exit
