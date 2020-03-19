# 网卡bond

> 网卡bond可以把多个物理网卡绑定成一个逻辑上的网卡，让它们使用同一个IP工作，    
> 在增加带宽的同时提高冗余性，常用来实现本地网卡的冗余。    
> 分别和不同交换机相连，可提高可靠性，也可以用来带宽扩容。简单来说就好像一辆大卡车准备了很多个备用轮胎，坏一个就可以换一个

> 网卡bond一般主要用于网络吞吐量很大，以及对于网络稳定性要求较高的场景。
>
> 主要是通过将多个物理网卡绑定到一个逻辑网卡上，实现了本地网卡的冗余，带宽扩容以及负载均衡。
>
> Linux下一共有七种网卡bond方式，实现以上某个或某几个具体功能。
>
> 最常见的三种模式是bond0，bond1，bond6.



【bond0】

平衡轮循环策略，有自动备援，不过需要"Switch"支援及设定。

balance-rr（Round-robin policy）

方式：

传输数据包的顺序是依次传输（即：第一个包走eth0，第二个包就走eth1……，一直到所有的数据包传输完成）。

优点：

提供负载均衡和容错能力。

缺点：

同一个链接或者会话的数据包从不同的接口发出的话，中间会经过不同的链路，在客户端可能会出现数据包无法有序到达的情况，而无序到达的数据包将会被要求重新发送，网络吞吐量反而会下降。



【bond1】

主-备份策略

active-backup（Active -backup policy）

方式：

只有一个设备处于活动状态，一个宕掉之后另一个马上切换为主设备。

mac地址为外部可见，从外面看，bond的mac地址是唯一的，switch不会发生混乱。

优点：

提高了网络连接的可靠性。

缺点：

此模式只提供容错能力，资源利用性较低，只有一个接口处于active状态，在有N个网络接口bond的状态下，利用率只有1/N。



【bond2】

平衡策略

balance-xor（XOR policy）

方式：

基于特性的Hash算法传输数据包。

缺省的策略为：(源MAC地址 XOR 目标MAC地址) % slave数量。 # XRO为异或运算，值不同时结果为1，相同为0

可以通过xmit_hash_policy选项设置传输策略。

特点：

提供负载均衡和容错能力。



【网卡绑定】

<2>查看网卡2的信息

ethtool eth2

如果Link detectedyes ，代表有网线插入
如果Link detected:no ，代表网口未启动。用ifconfig eth2 up启动，如果用查看仍然为no，说明此网卡没有网线插入。

<3>关闭NetworkManager(临时和永久最好都关闭）
network与NetworkManager是会冲突的

chkconfig NetworkManager off(centos6)
systemctl disable networkmanager(centos7)

service NetworkManager stop（centos6）
systemctl stop networkmanager(centos7)


我们假定前条件：

2个物理网口eth0，eth1

绑定后的虚拟口为bond0

服务器IP为10.10.10.1

配置文件：

\1. vi /etc/sysconfig/network-scripts/ifcfg-bond0

DEVICE=bond0

BOOTPROTO=none

ONBOOT=yes

IPADDR=10.10.10.1

NETMASK=255.255.255.0

NETWORK=192.168.0.0

\2. vi /etc/sysconfig/network-scripts/ifcfg-eth0

DEVICE=eth0

BOOTPROTO=none

MASTER=bond0

SLAVE=yes

\3. vi /etc/sysconfig/network-scripts/ifcfg-eth1

DEVICE=eth1

BOOTPROTO=none

MASTER=bond0

SLAVE=yes

修改modprobe相关设定文件，并加载bonding模块：

\1. vi /etc/modprobe.d/bonding.conf

alias bond0 bonding

options bonding mode=0 miimon=200

\2. 加载模块

modprobe bonding

\3. 确认是否加载成功

[root@slb ~]# lsmod | grep bonding

bonding 100065 0

\4. 重启网络

[root@slb ~]# /etc/init.d/network restart

[root@slb ~]# cat /proc/net/bonding/bond0

Ethernet Channel Bonding Driver: v3.5.0 (November 4, 2008)

Bonding Mode: fault-tolerance (active-backup)

Primary Slave: None

Currently Active Slave: eth0

……

[root@slb ~]# ifconfig |grep HWaddr

bond0 Link encap:Ethernet HWaddr 00:16:36:1B:BB:74

eth0 Link encap:Ethernet HWaddr 00:16:36:1B:BB:74

eth1 Link encap:Ethernet HWaddr 00:16:36:1B:BB:74

以上信息可以确认：

a. 现在的bonding模式是active-backup

b. 现在Active的网口是eth0

c. bond0, eth1的物理地址和处于active状态下的eth0的物理地址相同，这样是为了避免上位交换机发生混乱。

可以随意拔掉一根网线或者在交换机上shutdown一个网口，查看网络是否依旧联通。

\5. 系统启动自动绑定并增加默认网关（可选）

[root@slb ~]# vi /etc/rc.d/rc.local

ifenslave bond0 eth0 eth1

route add default gw 10.10.10.1