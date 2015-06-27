#!/bin/bash

SRC_LOACTION=/usr/local/src
MYSQL_DISTRIBUTION=mysql-5.6.25

function show_head(){
	echo $'\n++++++++++++++++++++++++BEGIN++++++++++++++++++++++++++++++++++'
}

function show_tail(){
	echo '++++++++++++++++++++++++END++++++++++++++++++++++++++++++++++'
}

show_head
echo "Preparing environment.........."
show_tail

echo "`rpm -qa|grep mysql`" >tmp.list
if [[ ! -s tmp.list ]]
then
        echo "Never have installed mysql."
else
        exec <tmp.list
        while read line
        do
                echo $line
        done
fi

yum -y install make gcc-c++ cmake bison-devel  ncurses-devel
yum install libaio libaio-devel -y
yum install perl-Data-Dumper -y
yum install net-tools -y

show_head
echo "Installing mysql.........."
show_tail
cd $SRC_LOACTION
tar xf $MYSQL_DISTRIBUTION
cd $MYSQL_DISTRIBUTION

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

