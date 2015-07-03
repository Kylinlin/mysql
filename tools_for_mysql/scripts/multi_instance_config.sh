#!/bin/bash
#Author:		kylin
#Date:			2015年7月3日
#Email:			kylinlingh@foxmail.com
#Usage:			将mysql改为多实例配置			


. /etc/rc.d/init.d/functions

function show_head(){
	echo $'\n++++++++++++++++++++++++BEGIN++++++++++++++++++++++++++++++++++'
}

function show_tail(){
	echo '++++++++++++++++++++++++END++++++++++++++++++++++++++++++++++'
}

show_head
echo "Let's begin the magic trip.........."
show_tail
read -p "Insert the port number you want to use for mysql connection: " PORT_NUM
read -p "Enter your password for mysql: " MYSQL_PASSWORD
mkdir -p /data/$PORT_NUM/data
mkdir -p /data/$PORT_NUM/log

firewall-cmd --zone=public --add-port=$PORT_NUM/tcp --permanent
firewall-cmd --reload

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
#server-id=1
#log-bin=mysql-bin
#log-bin-index= mysql-bin.index
 
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
find /data -name mysql -exec chmod 700 {} \;

cd /usr/local/mysql/scripts
./mysql_install_db --defaults-file=/data/$PORT_NUM/my.cnf --user=mysql --basedir=/usr/local/mysql --datadir=/data/$PORT_NUM/data

show_head
echo "Start mysql.........."
show_tail
echo "Starting mysql, please wait for 15 seconds;"
/data/$PORT_NUM/mysql start
sleep 15
CHECK_MYSQL_START=`netstat -lntp | grep $PORT_NUM`
if [[ $CHECK_MYSQL_START != "" ]]
then
	action "Start Mysql: " /bin/true
	mysqladmin -u root -S /data/$PORT_NUM/mysql.sock password "$MYSQL_PASSWORD"
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
		mysqladmin -u root -S /data/$PORT_NUM/mysql.sock password "$MYSQL_PASSWORD"
		sed -i "s/mysql_pwd=\"\"/mysql_pwd=\"$MYSQL_PASSWORD\"/g" /data/$PORT_NUM/mysql 
	else
		echo "Mysql install failed;"
	fi

fi
