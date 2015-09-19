###安装方式：

在linux上执行命令：wget -qO- https://raw.github.com/Kylinlin/mysql/master/setup.sh | sh -x

###注意：
- 1.mysql的安装路径为：/usr/local/mysql
- 2.安装的信息会写入到你复制下来的git仓库中的log/install.log文件中，请务必查看该文件
- 3.安装完的mysql的密码是空的，记得尽快修改密码
- 4.scripts目录下还有几个在安装过程中没有使用到的文件，但每个文件都有特殊作用，参考下面的文件描述


###文件描述：
####scripts目录下的文件
- 1.install_mysql.sh：执行这个文件，就能自动安装mysql
- 2.multi_instanch.sh：执行这个文件，然后输入要配置的多实例的端口号和mysql登陆密码，就能自动配置多实例，生成的目录位于/data目录下
- 3.backup_mysql.sh ：执行这个文件，就能对主数据库进行备份，并且把备份文件上传到ftp服务器上，同时还会设定每日的00:00进行自动备份
- 4.replication.sh：执行这个文件，进行主从复制（灾难恢复），使用方法：
	- 1.要输入从服务器的mysql端口号
	- 2.如果备份文件存在于ftp服务器上就输入yes，如果存在于本地就输入no
	- 3.按照格式输入备份文件的日期，就可以了
