#!/bin/bash
#Author:		kylin
#Date:			2015年7月3日
#Email:			kylinlingh@foxmail.com
#Usage:			mysql自动化备份

CONTACT_MAIL=kylinlingh@foxmail.com

MYUSER=root
MYPASS="123456"
MYSOCK=/data/3306/mysql.sock

BACKUP_PATH=/server/backup/`date +%F`
mkdir -p $BACKUP_PATH
LOG_FILE=${BACKUP_PATH}/log_`date +%F`.log
DATA_FILE=${BACKUP_PATH}/data_`date +%F`.sql.gz

MYSQL_PATH=/usr/local/mysql/bin
MYSQL_CMD="$MYSQL_PATH/mysql -u$MYUSER -p$MYPASS -S $MYSOCK"
MYSQL_DUMP="$MYSQL_PATH/mysqldump -u$MYUSER -p$MYPASS -S $MYSOCK -A -B --flush-logs --single-transaction -e"

$MYSQL_CMD -e "flush tables with read lock;" 
echo "-----show master status result-----" >$LOG_FILE
$MYSQL_CMD -e "show master status;" >>$LOG_FILE
${MYSQL_DUMP} | gzip > $DATA_FILE
$MYSQL_CMD -e "unlock tables;"
mail -s "mysql slave log" $CONTACT_MAIL < $LOG_FILE
