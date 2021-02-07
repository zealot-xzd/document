# 创建macvlan网络
root@Kylin:/home/zhidong/pipework-master# docker network create -d macvlan   --subnet=10.212.21.0/16   --gateway=10.212.255.254   -o parent=eth0 my-macvlan-net

# eds-on-macvlan
docker run -itd --privileged --name eds-on-macvlan -v sf_data:/sf/data -v sf_log:/sf/log -v sf_config:/sf/config --network my-macvlan-net --ip 10.212.21.88 sds-all-in-one_add_port /usr/sbin/init


# 网卡混杂模式
开启ifconfig eth0 promisc
关闭ifconfig eth0 -promisc


ip link add link eth0 dev eth0m type macvlan mode bridge


修改网卡名称
vim /etc/default/grub 编辑以下行
GRUB_CMDLINE_LINUX="net.ifnames=0 biosdevname=0"

 执行update-grub使修改生效
