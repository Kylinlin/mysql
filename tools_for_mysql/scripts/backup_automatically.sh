#!/bin/bash
#Author:		kylin
#Date:			2015年7月3日
#Email:			kylinlingh@foxmail.com
#Usage:			mysql自动化备份

CONTACT_MAIL=kylinlingh@foxmail.com

MYUSER=root
MYPASS="123456"
MYSOCK=/data/3306/mysql.sock
BACKUP_DIR=/server/backup
BACKUP_LOG=$BACKUP_DIR/backup_log.log
TODAY=`date +%F`

FTPSERVER=192.168.1.205
KEEPDAY=1
FTPUSER=Administrator
FTPPASSWD=nf56slogic789654d

#delte files before 7 days ago
echo "-----------" `date +%F` "-----------" >>$BACKUP_LOG
echo -e "Delete period backup file: \c" >>$BACKUP_LOG
echo `find $BACKUP_DIR -mtime +$KEEPDAY` >>$BACKUP_LOG
#find $BACKUP_DIR -mtime +$KEEPDAY -exec rm {} \;

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

tar -zcf $TODAY.tar.gz $BACKUP_PATH

mail -s "mysql slave log" $CONTACT_MAIL < $LOG_FILE

#Use ftp to convert file to ftp
ftp -i -n <<EFO
open $FTPSERVER
user $FTPUSER $FTPPASSWD
cd mysql
lcd $BACKUP_DIR
hash
prompt
put $TODAY.tar.gz
close
bye
EFO