#!/bin/bash
#Arthur:		kylinlin
#Begin date:	2015/6/1
#End date:		2015/6/6
#Contact email:	kylinlingh@foxmail.com
#Usage:			To begin installing nagios on moniting host automatically
#Attention:	

TOOLS_LOCATION=/usr/local/src
TOOLS_NAME=tools_for_mysql

yum install lrzsz -y
yum install dos2unix -y
yum install unzip -y

cd $TOOLS_LOCATION
unzip $TOOLS_NAME.zip 
cd $TOOLS_LOCATION/$TOOLS_NAME
dos2unix scripts/*
cd scripts/
sh install_mysql.sh 2>&1 | tee $TOOLS_LOCATION/$TOOLS_NAME/log/mysql_install.log