#!/bin/bash
###############################################################
#File Name      :   backup.sh
#Arthor         :   kylin
#Created Time   :   Fri 18 Sep 2015 09:36:55 AM CST
#Email          :   kylinlingh@foxmail.com
#Github         :   https://github.com/Kylinlin
#Version        :   2.0
#Description    :   Backup mysql daily.
###############################################################

MYUSER=root
MYPASS="123456"
MYSOCK=/data/3307/mysql.sock
BACKUP_DIR=/server/backup
BACKUP_LOG=$BACKUP_DIR/backup.log
TODAY=`date +%F`

function Delete_Expired_Date {
    EXPIRED_PERIOD=7
	if [[ ! -d $BACKUP_DIR ]]; then
		mkdir -p $BACKUP_DIR
	fi
	if [[ ! -f $BACKUP_LOG ]]; then
		touch $BACKUP_LOG
	fi
    echo "+-----------------------"$TODAY"-------------------------+" >> $BACKUP_LOG    
    echo "Deleting expired backup file: " >> $BACKUP_LOG
    echo `find $BACKUP_DIR -mtime +$EXPIRED_PERIOD` >> $BACKUP_LOG
    find $BACKUP_DIR -mtime +$EXPIRED_PERIOD -exec rm -rf {} \;
}

function Backup_Date {
    #Create directory for everyday
    BACKUP_PATH=/server/backup/$TODAY
    mkdir -p $BACKUP_PATH
    LOG_FILE=${BACKUP_PATH}/log_$TODAY.log
    DATA_FILE=${BACKUP_PATH}/data_$TODAY.sql.gz

    MYSQL_PATH=/usr/local/mysql/bin
    MYSQL_CMD="$MYSQL_PATH/mysql -u$MYUSER -p$MYPASS -S $MYSOCK"
    MYSQL_DUMP="$MYSQL_PATH/mysqldump -u$MYUSER -p$MYPASS -S $MYSOCK -A -B --flush-logs --single-transaction -e"

    $MYSQL_CMD -e "flush tables with read lock;" 
    echo "-----show master status result-----" >$LOG_FILE
    $MYSQL_CMD -e "show master status;" >>$LOG_FILE
    ${MYSQL_DUMP} | gzip > $DATA_FILE
    $MYSQL_CMD -e "unlock tables;"

    cd $BACKUP_DIR
    tar -zcf $TODAY.tar.gz $TODAY/

	#yum install mail -y > /dev/null
    #CONTACT_MAIL=kylinlingh@foxmail.com
    #mail -s "mysql slave log" $CONTACT_MAIL < $LOG_FILE
}

function Upload_Backup_Files {

    FTPSERVER=192.168.1.205
    FTPUSER=Administrator
    FTPPASSWD=nf56slogic789654d

ftp -i -n <<EFO
open $FTPSERVER
user $FTPUSER $FTPPASSWD
cd mysql
lcd $BACKUP_DIR
hash
binary
prompt
put $TODAY.tar.gz
close
bye
EFO

}

function Set_Crontab {
    MY_CRON=/var/spool/cron/`whoami`
    echo "# user:root task:backup all databases in mysql period:00:00 on everyday" >> $MY_CRON
    echo "00 00 * * * /bin/sh /server/backup_mysql.sh >/dev/null 2>&1" >> $MY_CRON
    systemctl start crond > /dev/null
}

#Call function
Delete_Expired_Date
Backup_Date
Upload_Backup_Files
Set_Crontab