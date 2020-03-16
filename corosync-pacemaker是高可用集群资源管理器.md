corosync是集群框架引擎程序，pacemaker是高可用集群资源管理器，crmsh是pacemaker的命令行工具。

一、NTP对时，免密钥登陆
[root@node-1 ~]# vim /etc/hosts
192.168.43.128 node-2
192.168.43.129 node-1
[root@node-1 ~]# ssh-keygen
[root@node-1 ~]# ssh-copy-id -i /root/.ssh/id_rsa root@node-2
[root@node-1 corosync]# scp /etc/hosts node-2:/etc/hosts
[root@node-1 ~]# ssh node-2
[root@node-1 ~]# yum install ntp -y
[root@node-2 ~]# hwclock -s //将硬件主板时钟设为系统时钟，比ntpdate和date -s命令强多了

[root@node-2 ~]# ssh-keygen
[root@node-2 ~]# ssh-copy-id -i /root/.ssh/id_rsa root@node-1
[root@node-2 ~]# ssh node-1
[root@node-2 ~]# yum install ntp -y

二、安装corosync、pacemaker

[root@node-1 corosync]# yum install corosync pacemaker -y //centos自带源即可，也可以只安装pcs即可。
[root@node-2 ~]# yum install corosync pacemaker -y
[root@node-1 ~]# vim /etc/yum.repos.d/crm.repo
--------------------------------
[network_ha-clustering_Stable]
name=Stable High Availability/Clustering packages (CentOS_CentOS-7)
type=rpm-md
baseurl=http://download.opensuse.org/repositories/network:/ha-clustering:/Stable/CentOS_CentOS-7/
gpgcheck=1
gpgkey=http://download.opensuse.org/repositories/network:/ha-clustering:/Stable/CentOS_CentOS-7/repodata/repomd.xml.key
enabled=1
-------------------------------
[root@node-1 ~]# yum install crmsh -y

[root@node-1 corosync]# cd /etc/corosync
[root@node-1 corosync]# cp corosync.conf.example corosync.conf
[root@node-1 corosync]# vim corosync.conf
bindnetaddr: 192.168.43.0
service {
var: 0
name: pacemaker #表示启动pacemaker
}
------------------------
corosync的节点直接需要密钥的。
[root@node-1 corosync]# mv /dev/{random,random.bak}
[root@node-1 corosync]# ln -s /dev/urandom /dev/random
[root@node-1 corosync]# corosync-keygen
Corosync Cluster Engine Authentication key generator.
Gathering 1024 bits for key from /dev/random.
Press keys on your keyboard to generate entropy.
Writing corosync key to /etc/corosync/authkey.
[root@node-1 corosync]# scp corosync.conf authkey root@node-2:/etc/corosync/
[root@node-1 corosync]# systemctl start corosync;ssh node-2 systemctl start corosync //两台机器同时启动corosync服务

=====================
马哥运维理论：
资源管理层（pacemaker负责仲裁指定谁是活动节点、IP地址的转移、本地资源管理系统）、消息传递层负责心跳信息（heartbeat、corosync）、Resource Agent（理解为服务脚本）负责服务的启动、停止、查看状态。多个节点上允许多个不同服务，剩下的2个备节点称为故障转移域，主节点所在位置只是相对的，同样，第三方仲裁也是相对的。vote system:少数服从多数。当故障节点修复后，资源返回来称为failback，当故障节点修复后，资源仍在备用节点，称为failover。
CRM：cluster resource manager ===>pacemaker心脏起搏器，每个节点都要一个crmd（5560/tcp）的守护进程，有命令行接口crmsh和pcs(在heartbeat v3，红帽提出的)编辑xml文件，让crmd识别并负责资源服务的处理。也就是说crmsh和pcs等价。
Resource Agent,OCF(open cluster framework)
primtive：主资源，在集群中只运行一个实例。clone：克隆资源，在集群中可运行多个实例。每个资源都有一定的优先级。
无穷大+负无穷大=负无穷大。主机名要和DNS解析的名称相同才行。

一、安装pcs管理工具
[root@node-1 ~]# ansible corosync -m service -a "name=pcsd state=started enabled=yes" //下载ansible，定义主机组为corosync
[root@node-1 ~]# systemctl status pcsd ;ssh node-2 "systemctl status pcsd"
[root@node-1 ~]# ansible corosync -m shell -a "echo "passw0rd"|passwd --stdin hacluster" ##单独创建用户，并设定密码，让用户名进行认证。
[root@node-1 ~]# pcs cluster auth node-2 node-1 ##本机的pcs客户端向pcsd的守护进程发起请求，如果向远端node-1的pcsd进行认证不通过，可能是firewalld的关系
Username: hacluster
Password:
node-1: Authorized
node-2: Authorized
[root@node-2 yum.repos.d]# pcs cluster auth node-1 node-2 //最好进行双向认证。
Username: hacluster
Password:
node-1: Authorized
node-2: Authorized


二、建立集群
[root@node-1 corosync]# pcs cluster setup --name mycluster node-1 node-2 --force
[root@node-2 corosync]# cat corosync.conf //执行完创建集群的命令后，会在节点之间单独产生一个配置文件
totem {
version: 2
secauth: off
cluster_name: mycluster
transport: udpu
}

nodelist {
node {
ring0_addr: node-1
nodeid: 1
}

node {
ring0_addr: node-2
nodeid: 2
}
}

quorum {
provider: corosync_votequorum
two_node: 1
}

logging {
to_logfile: yes
logfile: /var/log/cluster/corosync.log
to_syslog: yes
}

解释：totem是两个节点进行心跳传播的协议，ring 0代表不需要向任何信息就能到达。
[root@node-1 ~]# pcs cluster start
[root@node-1 ~]# pcs cluster status
Cluster Status:
Stack: unknown
Current DC: NONE
Last updated: Sat Oct 28 20:17:56 2017
Last change: Sat Oct 28 20:17:52 2017 by hacluster via crmd on node-1
2 nodes configured
0 resources configured
PCSD Status:
node-2: Online
node-1: Online
[root@node-2 ~]# pcs cluster start ##每个节点要单独启动pcsd守护进程。
Starting Cluster...
[root@node-2 ~]# corosync-cfgtool -s
Printing ring status.
Local node ID 2
RING ID 0
id = 192.168.43.128
status = ring 0 active with no faults
[root@node-2 ~]# corosync-cmapctl |grep members ##检查当前的集群成员情况
runtime.totem.pg.mrp.srp.members.1.config_version (u64) = 0
runtime.totem.pg.mrp.srp.members.1.ip (str) = r(0) ip(192.168.43.129)
runtime.totem.pg.mrp.srp.members.1.join_count (u32) = 1
runtime.totem.pg.mrp.srp.members.1.status (str) = joined
runtime.totem.pg.mrp.srp.members.2.config_version (u64) = 0
runtime.totem.pg.mrp.srp.members.2.ip (str) = r(0) ip(192.168.43.128)
runtime.totem.pg.mrp.srp.members.2.join_count (u32) = 1
runtime.totem.pg.mrp.srp.members.2.status (str) = joined
[root@node-1 ~]# pcs status ##DC(Designated Coordinator)的意思是说指定的协调员
每个node都有CRM，会有一个被选为DC，是整个Cluster的大脑，这个DC控制的CIB(cluster information base)是master CIB，其他的CIB都是副本
Cluster name: mycluster
WARNING: no stonith devices and stonith-enabled is not false ##stonith没有启用隔离设备，也就是说在抢占资源的时候直接把对方给爆头
Stack: corosync
Current DC: node-1 (version 1.1.16-12.el7_4.4-94ff4df) - partition with quorum
Last updated: Sat Oct 28 20:28:01 2017
Last change: Sat Oct 28 20:18:13 2017 by hacluster via crmd on node-1
2 nodes configured
0 resources configured
Online: [ node-1 node-2 ]
No resources
Daemon Status:
corosync: active/disabled
pacemaker: active/disabled
pcsd: active/enabled
[root@node-2 ~]# pcs status corosync
Membership information
----------------------
Nodeid Votes Name
2 1 node-2 (local)
1 1 node-1
[root@node-1 ~]# crm_verify -L -V ##crm_verify命令用来验证当前的集群配置是否有错误
error: unpack_resources: Resource start-up disabled since no STONITH resources have been defined
error: unpack_resources: Either configure some or disable STONITH with the stonith-enabled option
error: unpack_resources: NOTE: Clusters with shared data need STONITH to ensure data integrity
Errors found during check: config not valid
[root@node-1 ~]# pcs property set stonith-enabled=false
[root@node-1 ~]# pcs property list ##查看已经更改过的集群属性，如果是全局的，使用pcs property --all
Cluster Properties:
cluster-infrastructure: corosync
cluster-name: mycluster
dc-version: 1.1.16-12.el7_4.4-94ff4df
have-watchdog: false
stonith-enabled: false

三、安装crmsh命令行集群管理工具
[root@node-1 yum.repos.d]# wget http://download.opensuse.org/repositories/network:/ha-clustering:/Stable/CentOS_CentOS-7/network:ha-clustering:Stable.repo
crm(live)# configure
crm(live)configure# edit ##编辑集群属性，类似于vim模式，修改后保存退出。

crm部署web service:
VIP:
httpd:
两个节点安装httpd，注意，只能停止httpd服务，而不能重启，并且不能设置为开机自启动，因为resource manager会自动管理这些服务的运行或停止。
node-1和node-2均做以下步骤：
[root@node-2 ~]# systemctl start httpd
[root@node-2 ~]# echo "<h1>corosync pacemaker on the openstack</h1>" >/var/www/html/index.html
[root@node-1 ~]# systemctl start httpd ##httpd不能够设置为enable，得靠crm自己管理
[root@node-1 ~]# echo "<h1>corosync pacemaker on the openstack</h1>" >/var/www/html/index.html
此时，可以从浏览器访问2个节点的web界面
[root@node-2 ~]# crm
crm(live)# status ##必须保证所有节点都上线，才执行那些命令
crm(live)# ra
crm(live)ra# list systemd
httpd
crm(live)ra# help info
crm(live)ra# classes
crm(live)ra# cd
crm(live)# configure
crm(live)configure# help primitive

1、添加webIP资源
crm(live)ra# classes
crm(live)ra# list ocf ##ocf是classes
crm(live)ra# info ocf:IPaddr ##IPaddr是provider
crm(live)configure# primitive WebIP ocf:IPaddr params ip=192.168.43.120
crm(live)configure# show
node 1: node-1
node 2: node-2
primitive WebIP IPaddr \
params ip=192.168.43.120
property cib-bootstrap-options: \
have-watchdog=false \
dc-version=1.1.13-10.el7-44eb2dd \
cluster-infrastructure=corosync \
cluster-name=mycluster \
stonith-enabled=false
crm(live)configure# verify
crm(live)configure# commit
crm(live)# status
WebIP (ocf::heartbeat:IPaddr): Stopped
2、添加webservice资源
crm(live)configure# primitive WebServer systemd:httpd ##systemd是classes命令看到的
crm(live)configure# verify
WARNING: WebServer: default timeout 20s for start is smaller than the advised 100
WARNING: WebServer: default timeout 20s for stop is smaller than the advised 100
crm(live)configure# commit

3、webip和webserver绑定组资源
crm(live)configure# help group
crm(live)configure# group WebService WebIP WebServer ##它们之间是有顺序的，IP在哪儿，webserver就在哪儿
crm(live)configure# verify
WARNING: WebServer: default timeout 20s for start is smaller than the advised 100
WARNING: WebServer: default timeout 20s for stop is smaller than the advised 100
crm(live)configure# commit


crm(live)configure# node standby ##把当前节点设为备节点


四、如何保证某节点故障而后上线，资源不会从另一个节点转移回来？
学习文档：http://blog.51cto.com/nmshuishui/1399811

 

+++++++++++++++++++++++++++++++排错笔记++++++++++++++++++++++++++
1、node-1节点执行crm status发现OFFLINE: [ node-1 node-2 ] ，node-2节点执行crm status发现Online: [ node-2 ]，OFFLINE: [ node-1 ] ？
解决：NTP不对时问题
（1）[root@node-2 ~]# systemctl status pcsd;ssh node-1 "systemctl status pcsd" ##均正常
[root@node-2 ~]# systemctl status corosync;ssh node-1 "systemctl status corosync" ##均为active
两节点均可以ping通和互相SSH，于是查看corosync和pcsd日志，无明显error
（2）怀疑认证密钥不通过了，结果不是
[root@node-1 ~]# pcs cluster auth node-1 node-2
node-1: Already authorized
node-2: Already authorized
[root@node-2 ~]# pcs cluster auth node-1 node-2
node-1: Already authorized
node-2: Already authorized
（3）[root@node-1 ~]# crm status ##原因是packmaker挂了，[root@node-1 ~]# systemctl status crm_mon
ERROR: status: crm_mon (rc=107): Connection to cluster failed: Transport endpoint is not connected
（4）[root@node-1 ~]# systemctl status pacemaker ##看了博客才发觉NTP又没同步过来
Active: failed (Result: exit-code)
[root@node-1 ~]# vim /etc/ntp.conf
server 192.168.43.128 burst iburst prefer
[root@node-2 ~]# vim /etc/ntp.conf
server 127.127.1.0
fudge 127.127.1.0 stratum 10
发现重启NTP还是没有卵用，只能date -s "23:52:10"了
[root@node-1 ~]# date ; ssh node-2 "date"
2017年 12月 01日 星期五 23:57:55 CST
2017年 12月 01日 星期五 23:57:56 CST
（5）最后，两个节点重启systemctl restart pacemaker，运行crm status，卧槽，终于Online: [ node-1 node-2 ]了。
参考文档：http://blog.51cto.com/nmshuishui/1399811

2、corosync服务起不来，进而导致pacemaker服务无法启动？
报错：[root@node-2 ~]# crm status
ERROR: status: crm_mon (rc=107): Connection to cluster failed: Transport endpoint is not connected
[root@node-2 ~]# systemctl status pacemaker
● pacemaker.service - Pacemaker High Availability Cluster Manager
Loaded: loaded (/usr/lib/systemd/system/pacemaker.service; enabled; vendor preset: disabled)
Active: inactive (dead)
Dec 04 19:57:28 node-2 systemd[1]: Dependency failed for Pacemaker High Availability Cluster Manager.
Dec 04 19:57:28 node-2 systemd[1]: Job pacemaker.service/start failed with result 'dependency'.

解决：节点更换了IP地址，忘了更新hosts文件。注意：是所有节点都要更新Hosts文件
[root@node-2 ~]# tail /var/log/cluster/corosync.log
[4577] node-2 corosyncerror [MAIN ] parse error in config: No interfaces defined
[4577] node-2 corosyncerror [MAIN ] Corosync Cluster Engine exiting with status 8 at main.c:1414.
[root@node-2 ~]# vim /etc/hosts
#添加新的IP地址和主机名即可。
[root@node-2 ~]# systemctl restart corosync
[root@node-2 ~]# systemctl restart pacemaker

3、Pacemaker服务起不来？
报错：[root@node-2 ~]# systemctl status pacemaker
Active: deactivating (stop-sigterm) since Mon 2017-12-04 21:04:44 CST; 54s ago
Dec 04 21:04:44 node-2 pengine[4880]: warning: Processing failed op stop for WebIP on node-2: not configured (6)
Dec 04 21:04:44 node-2 pengine[4880]: error: Preventing WebIP from re-starting anywhere: operation stop faile...d' (6
解决：WebIP这个资源进程有问题，用cleanup清理掉进程即可。
[root@node-2 ~]# crm resource cleanup WebIP
crm(live)configure# delete WebIP ##删除一个组或资源都行
crm(live)configure# commit
[root@node-2 ~]# systemctl status pacemaker

4、删掉crm(live)configure# delete WebIP，依然报出WebIP (ocf::heartbeat:IPaddr): ORPHANED FAILED node-2 (unmanaged)
解决：[root@node-2 ~]# crm resource cleaup WebIP

5、node-1认为node-2不在线，node-2认为node-1不在线？
报错：[root@node-2 ~]# crm status
Online: [ node-2 ]
OFFLINE: [ node-1 ]
[root@node-1 ~]# crm status
Online: [ node-1 ]
OFFLINE: [ node-2 ]

未解决：两节点环境中，无法实现仲裁，那么每个节点都认为他是DC
[root@node-1 ~]# time=`date |awk '{print $5}'`;ssh node-2 date -s "$time" ##保证远程主机跟本机时间同步
[root@node-1 ~]# date ;ssh node-2 "date"
2017年 12月 04日 星期一 21:37:33 CST
2017年 12月 04日 星期一 21:37:33 CST

[root@node-2 ~]# systemctl list-unit-files|grep ntp ##开机保持NTP服务开启
ntpd.service enabled
[root@node-2 ~]# hwclock -w ##将当前系统时间写入BIOS

6、pacemaker服务有问题，报出配置文件格式有问题
[root@node-2 ~]# systemctl status pacemaker -l
Dec 04 21:52:35 node-2 cib[6776]: error: Completed cib_replace operation for section 'all': Update does not conform to the configured schema
解决：corosync.conf配置文件都是一个关键字，然后一个空格，一个花括符，紧接着4个空格，但是在拷贝的时候格式发生了变化，所以最好不要scp，手动改
[root@node-2 corosync]# vim corosync.conf
quorum {
provider: corosync_votequorum
two_node: 1
}