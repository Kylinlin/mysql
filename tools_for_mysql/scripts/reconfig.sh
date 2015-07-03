#!/bin/bash

SRC_LOCATION=/usr/local/src
TOOLS_LOACTION=$SRC_LOCATION/tools_for_mysql
MYSQL_DISTRIBUTION=mysql-5.6.25
MYSQL_LOCATION=/usr/local/mysql
MY_CNF=/data/3306/my.cnf
MYSQL=/data/3306/mysql

. /etc/rc.d/init.d/functions

function show_head(){
	echo $'\n++++++++++++++++++++++++BEGIN++++++++++++++++++++++++++++++++++'
}

function show_tail(){
	echo '++++++++++++++++++++++++END++++++++++++++++++++++++++++++++++'
}

read -p "Enter your password for mysql: " MYSQL_PASSWORD

pkill mysqld

show_head
echo "Adding user.........."
show_tail
CHECK_MYSQL_USER=`cat /etc/passwd | grep mysql`
if [[ $CHECK_MYSQL_USER == "" ]]
then
	groupadd mysql 
	useradd -g mysql mysql -s /sbin/nologin
fi
	
chown -R mysql:mysql $MYSQL_LOCATION

show_head
echo "Adding firewall.........."
show_tail
firewall-cmd --zone=public --add-port=3306/tcp --permanent
firewall-cmd --reload

show_head
echo "Configuring mysql.........."
show_tail
rm -rf /data/3306
mkdir -p /data/3306/data
mkdir -p /data/3306/log

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
server-id=1
#log-bin=mysql-bin
#log-bin-index= mysql-bin.index
 
# LOGGING
log_error=/data/3306/log/mysql-error.log
slow_query_log_file=/data/3306/log/mysql-slow.log
slow_query_log=1

EOF

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
./mysql_install_db --defaults-file=/data/3306/my.cnf --user=mysql --basedir=/usr/local/mysql --datadir=/data/3306/data

show_head
echo "Start mysql.........."
show_tail
source /etc/profile
source /etc/profile

echo "Starting mysql, please wait 15 seconds;"
/data/3306/mysql start
sleep 15
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

