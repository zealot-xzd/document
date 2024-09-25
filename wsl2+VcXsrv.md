1. 安装图形桌面
	sudo apt install ubuntu-desktop
	
	sudo vim ~/.bashrc 添加
	
	export DISPLAY=$(grep -m 1 nameserver /etc/resolv.conf |awk '{print $2}'):0.0
	export XDG_SESSION_TYPE=x11
	
	source ~/.bashrc
	
2. 在Ubuntu中输入sudo service dbus restart （建议每次重启桌面都执行一次该命令，重启dbus服务）

3. 在Ubuntu中输入gnome-session

4. 安装VcXsrv
	在Windows中启动XLaunch