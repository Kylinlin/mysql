#!/bin/bash
###############################################################
#File Name      :   replication.sh
#Arthor         :   kylin
#Created Time   :   Fri 18 Sep 2015 11:32:39 PM CST
#Email          :   kylinlingh@foxmail.com
#Blog           :   http://www.cnblogs.com/kylinlin/
#Github         :   https://github.com/Kylinlin
#Version        :
#Description    :
###############################################################

. /etc/rc.d/init.d/functions

MYUSER=root
MYPASS="123456"
MYSQL_PATH=/usr/local/mysql/bin

function Input_Info {
    
    while true; do
        while true; do
            echo -n -e "\e[1;36mEnter the port of mysql: \e[0m"
            read PORT_NUM
            if [[ ! -d /data/$PORT_NUM ]]; then
                echo -e "\e[1;31mThere is no $PORT_NUM under /data/ ,check it and reenter. \e[0m"
            else
                break 1;
            fi
        done

        echo -n -e "\e[1;36mEnter the data you want to rocll back(eg: 2015-07-03): \e[0m"
        read RECOVER_DATE
        echo -n -e "\e[1;36mDo you need to download the backup from server? yes or no: \e[0m"
        read DOWNLOAD
        echo -e "\e[1;32m+-----------------The recover informations you enter is here(灾难恢复信息)-----------------------------+
            Instance Port      : $PORT_NUM
            Date to rocll back : $RECOVER_DATE
            Need to download   : $DOWNLOAD
+------------------------------------------------------------------------------------------------------+\e[0m"
        echo -n -e "\e[1;36mConfirm it? yes or no: \e[0m"
        read CHECK
        if [[ $CHECK == 'yes' ]]; then
			echo -e "\e[1;32m+-----------------The recover informations you enter is here-------------------------------------+
				Instance Port      : $PORT_NUM
				Date to rocll back : $RECOVER_DATE
				Need to download   : $DOWNLOAD
+-------------------------------------------------------------------------------------------+\e[0m" >> ../log/install_mysql.log		
            break 2;
        fi
    done
}

function Recover_Date {

    FTPSERVER=192.168.1.205
    FTPUSER=Administrator
    FTPPASSWD=nf56slogic789654d

    cd /server/backup
    if [[ $DOWNLOAD == 'yes' ]]; then
        ftp -i -n <<EFO
            open $FTPSERVER
            user $FTPUSER $FTPPASSWD
            cd mysql
            binary
            get $RECOVER_DATE.tar.gz
            close
            bye
EFO
    tar -xf $RECOVER_DATE.tar.gz
    fi

    BACKUP_PATH=/server/backup/$RECOVER_DATE
    LOG_FILE=$BACKUP_PATH/log_$RECOVER_DATE.log
    DATA_FILE=$BACKUP_PATH/data_$RECOVER_DATE.sql.gz

    MYSOCK=/data/$PORT_NUM/mysql.sock
    MYSQL_CMD="$MYSQL_PATH/mysql -u$MYUSER -p$MYPASS -S $MYSOCK"

    cd ${BACKUP_PATH}
    gzip -d data_$RECOVER_DATE.sql.gz
    echo -e "\e[1;32mRecoving data to mysql...\e[0m"
    $MYSQL_CMD < data_$RECOVER_DATE.sql
}

function Synchronize {

    echo -e "\e[1;32mSynchroning data to remote server...\e[0m"
    BIN_LOG=`cat log_$RECOVER_DATE.log | awk 'NR==3 {print $1}'`
    BIN_LOG_POS=`cat log_$RECOVER_DATE.log | awk 'NR==3 {print $2}'`
    $MYSQL_CMD -e "stop slave;"

    $MYSQL_CMD -e "
    CHANGE MASTER TO  
    MASTER_HOST='192.168.1.139', 
    MASTER_PORT=3306,
    MASTER_USER='rep', 
    MASTER_PASSWORD='123456', 
    MASTER_LOG_FILE='$BIN_LOG',
    MASTER_LOG_POS=$BIN_LOG_POS;"

    $MYSQL_CMD -e "start slave;"

    REPLICATION_LOG=/server/backup/replication_`date +%F`.log
    CONTACT_EMAIL=kylinlingh@foxmail.com

    echo `date` > $REPLICATION_LOG
    $MYSQL_CMD -e "show slave status\G" >> $REPLICATION_LOG
}

function Check_State {
    Slave_IO_Running=`cat $REPLICATION_LOG | egrep "Slave_IO_Running" | awk 'NR==1 {print $2}'`
    Slave_SQL_Running=`cat $REPLICATION_LOG | egrep "Slave_SQL_Running" | awk 'NR==1 {print $2}'`

    if [[ $Slave_IO_Running == "Yes" ]]; then
        action "Slave_IO_Running: " /bin/true
    else
        action "Slave_IO_Running: " /bin/false
    fi

    if [[ $Slave_SQL_Running == "Yes" ]]; then
        action "Slave_SQL_Running: " /bin/true
    else
        action "Slave_SQL_Running: " /bin/false
    fi

    #mail -s "mysql slave result" $CONTACT_EMAIL < $REPLICATION_LOG
}

#Call the functions
Input_Info
Recover_Date
Synchronize
Check_State
