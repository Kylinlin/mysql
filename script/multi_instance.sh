#!/bin/bash
###############################################################
#File Name      :   multi_instance.sh
#Arthor         :   kylin
#Created Time   :   Thu 17 Sep 2015 06:38:51 PM CST
#Email          :   kylinlingh@foxmail.com
#Github         :   https://github.com/Kylinlin
#Version        :   2.0
#Description    :   Configure mysql with multiple instances.
###############################################################

. /etc/rc.d/init.d/functions

function Input_Info {
    
    while true; do
        while true; do
            echo -n -e "\e[1;36mEnter the port number(eg: 3307): \e[0m"
            read PORT_NUM
            if [[ ! -d /data/$PORT_NUM ]]; then
                break 1;
            else
                echo -e "\e[1;31mThe port you enter is already esists, delete it or reenter another number!\n\e[0m"
            fi
        done
        echo  -n -e "\e[1;36mEnter the password for mysql: \e[0m"
        read MYSQL_PASSWORD

        #Add port to firewall
        firewall-cmd --zone=public --add-port=$PORT_NUM/tcp --permanent > /dev/null
        firewall-cmd --reload > /dev/null

        echo -n -e "\e[1;36mEnter the id for your instance: \e[0m"
        read ID_INSTANCE

        echo -e "\e[1;32m**********The informations you enter is here**********
            Instance Number : $PORT_NUM
            Instance ID     : $ID_INSTANCE
            Mysql Password  : $MYSQL_PASSWORD 
*******************************************************\e[0m"
        echo -n -e "\e[1;36mConfirm it or not? yes or no: \e[0m"
        
        read CHECK
        if [[ $CHECK == 'yes' ]] ; then
            break 2;
        fi
    done

    mkdir -p /data/$PORT_NUM/data
    mkdir -p /data/$PORT_NUM/log

}

function Echo_Informations {
    echo -e "\e[1;32m\n+-----------------Informations for multiple instances（多实例安装信息）-------------------------------------+
    Englis Description:
   
    Instance Number            : $PORT_NUM
    Instancd ID                : $ID_INSTANCE
    Mysql data files' location : /data/$PORT_NUM/data
    Mysql configuration file   : /data/$PORT_NUM/my.cnf
    Mysql startup scripts      : /data/$PORT_NUM/mysql
    Mysql sock file            : /data/$PORT_NUM/mysql.sock

    Command to start mysql     : /data/$PORT_NUM/mysql start
    Command to stop mysql      : /data/$PORT_NUM/mysql stop
    Command to restart mysql   : /data/$PORT_NUM/mysql restart
    Command to connect mysql   : mysql -uroot -p'$MYSQL_PASSWORD' -S /data/$PORT_NUM/mysql.sock
    
    中文版说明：
    
    端口号                  ： $PORT_NUM
    实例ID                  :  $ID_INSTANCE
    Mysql的安装路径         ： /usr/local/mysql
    Mysql的数据文件存放路径 ： /data/$PORT_NUM/data
    Mysql的配置文件         ： /data/$PORT_NUM/my.cnf
    Mysql的启动文件         ： /data/$PORT_NUM/mysql
    Mysql的锁文件           :  /data/$PORT_NUM/mysql.sock
    
    启动mysql的命令         ： /data/$PORT_NUM/mysql start
    停止mysql的命令         ： /data/$PORT_NUM/mysql stop
    重启mysql的命令         ： /data/$PORT_NUM/mysql restart
    连接mysql的命令         ： mysql -uroot -p'$MYSQL_PASSWORD' -S /data/$PORT_NUM/mysql.sock
+---------------------------------------------------------------------------------------------+\e[0m" >> ../log/install.log   
}

function Configure {
   MY_CNF=/data/$PORT_NUM/my.cnf 
   cat >$MY_CNF<<EOF
[client]
port = $PORT_NUM
socket = /data/$PORT_NUM/mysql.sock
 
[mysqld]
port=$PORT_NUM
socket = /data/$PORT_NUM/mysql.sock
pid-file = /data/$PORT_NUM/data/mysql.pid
basedir = /usr/local/mysql
datadir = /data/$PORT_NUM/data
server-id=$ID_INSTANCE
log-bin=mysql-bin
log-bin-index= mysql-bin.index
 
# LOGGING
log_error=/data/$PORT_NUM/log/mysql-error.log
slow_query_log_file=/data/$PORT_NUM/log/mysql-slow.log
slow_query_log=1
EOF

    MYSQL=/data/$PORT_NUM/mysql

cat >$MYSQL<<EOF
#!/bin/sh

port=$PORT_NUM
mysql_user="root"
mysql_pwd=""
CmdPath="/usr/local/mysql/bin"

#startup function
function_start_mysql()
{
    printf "Starting MySQL...\n"
    /bin/sh \${CmdPath}/mysqld_safe --defaults-file=/data/\${port}/my.cnf 2>&1 > /dev/null &
}

#stop function
function_stop_mysql()
{
    printf "Stoping MySQL...\n"
    \${CmdPath}/mysqladmin -u \${mysql_user} -p\${mysql_pwd} -S /data/\${port}/mysql.sock shutdown
}

#restart function
function_restart_mysql()
{
    printf "Restarting MySQL...\n"
    function_stop_mysql
    sleep 2
    function_start_mysql
}

case \$1 in
start)
    function_start_mysql
;;
stop)
    function_stop_mysql
;;
restart)
    function_restart_mysql
;;
*)
    printf "Usage: /data/\${port}/mysql {start|stop|restart}\n"
esac
EOF
    
    chown -R mysql:mysql /data
    find /data -name mysql -exec chmod 700 {} \; > /dev/null

    cd /usr/local/mysql/scripts
    ./mysql_install_db --defaults-file=/data/$PORT_NUM/my.cnf --user=mysql --basedir=/usr/local/mysql --datadir=/data/$PORT_NUM/data > /dev/null

}

function Startup {

    /data/$PORT_NUM/mysql start
    sleep 15
    CHECK_MYSQL_START=`netstat -lntp | grep $PORT_NUM`
    if [[ $CHECK_MYSQL_START != "" ]]
    then
        action "Start Mysql: " /bin/true
        /usr/local/mysql/bin/mysqladmin -u root -S /data/$PORT_NUM/mysql.sock password "$MYSQL_PASSWORD"
        sed -i "s/mysql_pwd=\"\"/mysql_pwd=\"$MYSQL_PASSWORD\"/g" /data/$PORT_NUM/mysql 
    else
        action "Start Mysql: " /bin/false
        /data/$PORT_NUM/mysql restart
        sleep 15
        CHECK_MYSQL_START=`netstat -lntp | grep $PORT_NUM`
        if [[ $CHECK_MYSQL_START != "" ]]
        then
            echo "Restarting mysql, please wait 15 seconds;"
            action "Restart Mysql: " /bin/true
            /usr/local/mysql/bin/mysqladmin -u root -S /data/$PORT_NUM/mysql.sock password "$MYSQL_PASSWORD"
            sed -i "s/mysql_pwd=\"\"/mysql_pwd=\"$MYSQL_PASSWORD\"/g" /data/$PORT_NUM/mysql 
        else
            echo "Mysql install failed;"
        fi
    
    fi
}

#Call the functions
Input_Info
Echo_Informations
Configure
Startup