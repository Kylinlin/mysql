#!/bin/bash
#Author:		kylin
#Date:			2015年7月3日
#Email:			kylinlingh@foxmail.com
#Usage:			mysql配置主从复制

. /etc/rc.d/init.d/functions

MYUSER=root
MYPASS="123456"
MYSOCK=/data/3307/data/mysql.sock
MYSQL_PATH=/usr/local/mysql/bin
MYSQL_CMD="$MYSQL_PATH/mysql -u$MYUSER -p$MYPASS -S $MYSOCK"

read -p "Insert the date you wanna replication on,eg:2015-07-03: " RECOVER_DATE
BACKUP_PATH=/server/backup/$RECOVER_DATE
LOG_FILE=$BACKUP_PATH/log_$RECOVER_DATE.log
DATA_FILE=$BACKUP_PATH/data_$RECOVER_DATE.sql.gz


cd ${BACKUP_PATH}
gzip -d data_$RECOVER_DATE.sql.gz
$MYSQL_CMD < data_$RECOVER_DATE.sql

BIN_LOG=`cat log_$RECOVER_DATE.log | awk 'NR==3 {print $1}'`
echo $BIN_LOG
BIN_LOG_POS=`cat log_$RECOVER_DATE.log | awk 'NR==3 {print $2}'`
echo $BIN_LOG_POS

$MYSQL_CMD -e "stop slave;"

echo "Begin"

$MYSQL_CMD -e "
CHANGE MASTER TO  
MASTER_HOST='192.168.253.143', 
MASTER_PORT=3306,
MASTER_USER='rep', 
MASTER_PASSWORD='123456', 
MASTER_LOG_FILE='$BIN_LOG',
MASTER_LOG_POS=$BIN_LOG_POS;"

echo "End"
REPLICATION_LOG=/server/backup/replication_log_`date +%F`.log
CONTACT_EMAIL=kylinlingh@foxmail.com

echo `date` >> $REPLICATION_LOG
$MYSQL_CMD -e "show slave status\G" >> $REPLICATION_LOG

Slave_IO_Running=`cat $REPLICATION_LOG | egrep "IO_Running|SQL_Running" | awk 'NR==1 {print $2}'`
Slave_SQL_Running=`cat $REPLICATION_LOG | egrep "IO_Running|SQL_Running" | awk 'NR==2 {print $2}'`

if [[ $Slave_IO_Running == "Yes" ]]
then
	action "Slave_IO_Running: " /bin/true
else
	action "Slave_IO_Running: " /bin/false
fi

if [[ $Slave_SQL_Running == "Yes" ]]
then
	action "Slave_SQL_Running: " /bin/true
else
	action "Slave_SQL_Running: " /bin/false
fi

$MYSQL_CMD -e "start slave;"

mail -s "mysql slave result" $CONTACT_EMAIL < $REPLICATION_LOG


