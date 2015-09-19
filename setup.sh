#!/bin/bash
###############################################################
#File Name      :   setup_thr_network.sh
#Arthor         :   kylin
#Created Time   :   Sat 19 Sep 2015 04:04:15 AM CST
#Email          :   kylinlingh@foxmail.com
#Github         :   https://github.com/Kylinlin
#Version        :   1.0
#Description    :   Install mysql through network.
###############################################################
 
 
function Setup {
    yum install git dos2unix -y > /dev/null
    git clone https://github.com/Kylinlin/mysql.git
    cd mysql/script/
	dos2unix *
    sh install_mysql.sh
    if [[ ! -d /server ]]; then
        mkdir /server
    fi  
    cp backup_mysql.sh /server/
}
 
Setup