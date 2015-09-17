#!/bin/bash
###############################################################
#File Name      :   install_mysql.sh
#Arthor         :   kylin
#Created Time   :   Thu 17 Sep 2015 09:38:59 AM CST
#Email          :   kylinlingh@foxmail.com
#Github         :   https://github.com/Kylinlin
#Version        :   2.0
#Description    :   Install mysql with source code.
###############################################################

SRC_LOCATION=/usr/local/src
MYSQL_DISTRIBUTION=mysql-5.6.25
MYSQL_LOCATION=/usr/local/mysql
MY_CNF=/data/3306/my.cnf
MYSQL=/data/3306/mysql

. /etc/rc.d/init.d/functions

function Show_Informations {
    echo -n -e "\e[1;36mEnter the password for mysql: \e[0m"
    read MYSQL_PASSWORD
    echo -e "\e[1;32m+------------------------------------------------------+
        Here is the informations for your installation
   
    Mysql will be installed to : /usr/local/mysql
    Mysql data files' location : /data/3306/data
    Mysql configuration file   : /data/3306/my.cnf
    Mysql startup scripts      : /data/3306/mysql
    Mysql sock file            : /data/3306/mysql.sock

    Command to start mysql     : /data/3306/mysql start
    Command to stop mysql      : /data/3306/mysql stop
    Command to restart mysql   : /data/3306/mysql restart
    Command to connect mysql   : mysql -uroot -p$MYSQL_PASSWORD -S /data/3306/mysql.sock
+------------------------------------------------------+\e[0m" > ../log/install.log
}

#Install necessary tools for mysql
function Prepare_Env {
    yum install -y make gcc-c++ cmake bison-devel ncurses-devel > /dev/null
    yum install libaio libaio-devel -y /dev/null
    yum install perl-Data-Dumper -y > /dev/null 
    yum install ftp -y > /dev/null
    yum install net-tools -y > /dev/null
} 

function Compile {
    cd ../packages
    tar xf $MYSQL_DISTRIBUTION.tar.gz -C $SRC_LOCATION  
    cd $SRC_LOCATION/$MYSQL_DISTRIBUTION
    cmake \
        -DCMAKE_INSTALL_PREFIX=/usr/local/mysql \
        -DMYSQL_DATADIR=/usr/local/mysql/data \
        -DSYSCONFDIR=/etc \
        -DWITH_MYISAM_STORAGE_ENGINE=1 \
        -DWITH_INNOBASE_STORAGE_ENGINE=1 \
        -DWITH_MEMORY_STORAGE_ENGINE=1 \
        -DWITH_READLINE=1 \
        -DMYSQL_UNIX_ADDR=/var/lib/mysql/mysql.sock \
        -DMYSQL_TCP_PORT=3306 \
        -DENABLED_LOCAL_INFILE=1 \
        -DWITH_PARTITION_STORAGE_ENGINE=1 \
        -DEXTRA_CHARSETS=all \
        -DDEFAULT_CHARSET=utf8 \
        -DDEFAULT_COLLATION=utf8_general_ci 

    make && make install 
    return 0
}

function Configure {
    
    #Add user mysql
    CHECK_MYSQL_USER=`cat /etc/passwd | grep mysql`
    if [[ $CHECK_MYSQL_USER == "" ]]
    then
        groupadd mysql 
        useradd -g mysql mysql -s /sbin/nologin
    fi

    chown -R mysql:mysql $MYSQL_LOCATION

    #Add port to firewall
    firewall-cmd --zone=public --add-port=3306/tcp --permanent > /dev/null
    firewall-cmd --reload > /dev/null
    
    #Restore the data file to /data/3306/data
    rm -rf /data/3306
    mkdir -p /data/3306/data
    mkdir -p /data/3306/log

    #Configure file my.cnf
cat >$MY_CNF<<EOF
[client]
port = 3306
socket = /data/3306/mysql.sock
 
[mysqld]
port=3306
socket = /data/3306/mysql.sock
pid-file = /data/3306/data/mysql.pid
basedir = /usr/local/mysql
datadir = /data/3306/data
#server-id=1
#log-bin=mysql-bin
#log-bin-index= mysql-bin.index
 
# LOGGING
log_error=/data/3306/log/mysql-error.log
slow_query_log_file=/data/3306/log/mysql-slow.log
slow_query_log=1

EOF

#Add the mysql startup script 
cat >$MYSQL<<EOF
#!/bin/sh

port=3306
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
    find /data -name mysql -exec chmod 700 {} \;

    echo 'export PATH=$PATH:/usr/local/mysql/bin' >>/etc/profile
    source /etc/profile

    cd /usr/local/mysql/scripts
    ./mysql_install_db --defaults-file=/data/3306/my.cnf --user=mysql --basedir=/usr/local/mysql --datadir=/data/3306/data > /dev/null


}

function Startup {

    echo -e "\e[1;32mStarting mysql, please wait for 15 seconds;\e[0m"
    /data/3306/mysql start
    sleep 15

    source /etc/profile
    source /etc/profile

    CHECK_MYSQL_START=`netstat -lntp | grep 3306`
    if [[ $CHECK_MYSQL_START != "" ]]
    then
        action "Start Mysql: " /bin/true
        mysqladmin -u root -S /data/3306/mysql.sock password "$MYSQL_PASSWORD"
        sed -i "s/mysql_pwd=\"\"/mysql_pwd=\"$MYSQL_PASSWORD\"/g" /data/3306/mysql 
    else
        action "Start Mysql: " /bin/false
        /data/3306/mysql restart
        sleep 15
        CHECK_MYSQL_START=`netstat -lntp | grep 3306`
        if [[ $CHECK_MYSQL_START != "" ]]
        then
            echo "Restarting mysql, please wait 15 seconds;"
            action "Restart Mysql: " /bin/true
            mysqladmin -u root -S /data/3306/mysql.sock password "$MYSQL_PASSWORD"
            sed -i "s/mysql_pwd=\"\"/mysql_pwd=\"$MYSQL_PASSWORD\"/g" /data/3306/mysql 
        else
            echo "Mysql install failed;"
        fi
    
    fi
    
    echo -e -n "\e[1;36mDo you want to configure more instance, yes or no: \e[0m" 
    read MULTI_INSTANCH
    if [[ $MULTI_INSTANCH == 'yes' ]]
    then
        sh multi_instance_config.sh
    fi
    
}

#Call All functions
Show_Informations
Prepare_Env
Compile
Configure
Startup