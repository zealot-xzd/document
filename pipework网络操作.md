添加网络接口
pipework br1 $APACHE 192.168.1.1/24

This will:

create a bridge named br1 in the docker host;
add an interface named eth1 to the $APACHE container;
assign IP address 192.168.1.1 to this interface,
connect said interface to br1.


Now (drum roll), let's do this:

pipework br1 $MYSQL 192.168.1.2/24
This will:

not create a bridge named br1, since it already exists;
add an interface named eth1 to the $MYSQL container;
assign IP address 192.168.1.2 to this interface,
connect said interface to br1.

添加网络接口同时修改接口名称
pipework br1 -i eth2 容器id 192.168.1.3/24

设置网关
pipework br1 -i eth2 容器id 192.168.1.3/24@192.168.4.1



# 添加默认路由
linux下静态路由修改命令
方法一：
添加路由
route add -net 192.168.0.0/24 gw 192.168.0.1
route add -host 192.168.1.1 dev 192.168.0.1
删除路由
route del -net 192.168.0.0/24 gw 192.168.0.1

add 增加路由
del 删除路由
-net 设置到某个网段的路由
-host 设置到某台主机的路由
gw 出口网关 IP地址
dev 出口网关 物理设备名

增 加默认路由

route add default gw 192.168.0.1
默认路由一条就够了

route -n 查看路由表

方法二：
添加路由
ip route add 192.168.0.0/24 via 192.168.0.1
ip route add 192.168.1.1 dev 192.168.0.1
删除路由
ip route del 192.168.0.0/24 via 192.168.0.1


add 增加路由
del 删除路由
via 网关出口 IP地址
dev 网关出口 物理设备名

增加默认路由
ip route add default via 192.168.0.1 dev eth0
via 192.168.0.1 是我的默认路由器

查看路由信息
ip route

保存路由设置，使其在网络重启后任然有效
在/etc/sysconfig/network-script/目录下创建名为route- eth0的文件
vi /etc/sysconfig/network-script/route-eth0
在此文件添加如下格式的内容

192.168.1.0/24 via 192.168.0.1

重启网络验证

 
/etc/rc.d/init.d/network中有这么几行：

# Add non interface-specific static-routes.
if [ -f /etc/sysconfig/static-routes ]; then
grep "^any" /etc/sysconfig/static-routes | while read ignore args ; do
/sbin/route add -$args
done
fi

也就是说，将静态路由加到/etc/sysconfig/static-routes 文件中就行了。
 
如加入：
route add -net 11.1.1.0 netmask 255.255.255.0 gw 11.1.1.1

则static-routes的格式为
any net 11.1.1.0 netmask 255.255.255.0 gw 11.1.1.1



ip link set eth0m up
ip addr add 10.1.1.123/24 dev eth0m
route add default gw 10.1.1.254

修改网卡名称
ip link set ens192 down
ip link set ens192 name eth0
ip link set eth0 up
