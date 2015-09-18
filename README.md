###安装方式：

- 1.在linux上执行命令：wget -qO- https://raw.github.com/Kylinlin/Install_Mysql_On_Centos7/master/setup_thr_network.sh | sh -x
- 2.在安装过程中会要求输入mysql的启动密码（大概会在开始安装后的1分钟左右）
- 3.mysql的编译安装需要大概20到30分钟，在安装mysql的最后会询问是否配置多实例，是则输入yes，否则输入no

###注意：
- 1.mysql的安装路径为：/usr/local/mysql
- 2.使用了多实例的安装方式，使用了3306端口，启动mysql的命令为：mysql -uroot -p -S /data/3306/mysql.sock
- 3.mysql的启动密码写入到了/data/3306/mysql文件中



###文件描述：
####script/目录下的文件
- 1.install_mysql.sh：执行这个文件，就能自动安装mysql
- 2.multi_instanch.sh：执行这个文件，然后输入要配置的多实例的端口号和mysql登陆密码，就能自动配置多实例，生成的目录位于/data目录下
- 3.backup_mysql.sh ：执行这个文件，就能对主数据库进行备份，并且把备份文件上传到ftp服务器上
- 4.replication.sh：执行这个文件，进行主从复制。注意几点：
	- 1.要输入从服务器的mysql端口号。
	- 2.如果备份文件存在于ftp服务器上就输入yes，如果存在于本地就输入no。
	- 3.按照格式输入备份文件的日期，就可以了。
