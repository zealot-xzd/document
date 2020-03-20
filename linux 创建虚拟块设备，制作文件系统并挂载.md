# linux 创建虚拟块设备，制作文件系统并挂载

# losetup
	-a  显示所有已经使用的回环设备状态 
	-d  卸除回环设备 
	-f  寻找第一个未使用的回环设备 
	-e  <加密选项> 启动加密编码  

	[root@rhel6 ~]# losetup -f    //查找第一个未使用的回环设备 
	/dev/loop0 
	[root@rhel6 ~]# losetup -a   //显示所有已经使用的回环设备状态 
	[root@rhel6 ~]# dd if=/dev/zero of=loop.img bs=10M count=10 
	10+0 records in 
	10+0 records out 
	104857600 bytes (105 MB) copied, 0.794912 s, 132 MB/s 
	[root@rhel6 ~]# losetup -f loop.img   //将 loop.img 虚拟成第一个未使用的回环设备 
	[root@rhel6 ~]# losetup -a 
	/dev/loop0: [fd00]:26524 (/root/loop.img) 
	[root@rhel6 ~]# losetup -f 
	/dev/loop1 
	[root@rhel6 ~]# mkfs.ext4 /dev/loop0 
	[root@rhel6 ~]# mount /dev/loop0 /mnt/ 
	[root@rhel6 ~]# df -h 
	Filesystem            Size  Used Avail Use% Mounted on 
	/dev/mapper/Lrhel6-root 
	                      3.9G  2.4G  1.4G  64% / 
	tmpfs                 499M     0  499M   0% /dev/shm 
	/dev/sda1              49M   27M   20M  59% /boot 
	/dev/loop0             97M  5.6M   87M   7% /mnt 

	[root@rhel6 ~]# umount /mnt/ 
	[root@rhel6 ~]# losetup -d /dev/loop0                           //卸除回环设备



回环设备（ 'loopback device'）
允许用户以一个普通磁盘文件虚拟一个块设备。设想一个磁盘设备，对它的所有读写操作都将被重定向到读写一个名为 disk-image 的普通文件而非操作实际磁盘或分区的轨道和扇区。（当然，disk-image 必须存在于一个实际的磁盘上，而这个磁盘必须比虚拟的磁盘容量更大。）回环设备允许你这样使用一个普通文件。

回环设备以 /dev/loop0、/dev/loop1 等命名。每个设备可虚拟一个块设备。注意只有超级用户才有权限设置回环设备。

回环设备的使用与其它任何块设备相同。特别是，你可以在这个设备上创建文件系统并像普通的磁盘一样将它挂载在系统中。这样的一个将全部内容保存在一个普通文件中的文件系统，被称为虚拟文件系统（virtual file system）（译者注：这个用法并不常见。VFS 通常另有所指，如指代 Linux 内核中有关文件系统抽象的代码层次等）。


1. 什么是loop设备？

loop设备是一种伪设备，是使用文件来模拟块设备的一种技术，文件模拟成块设备后, 就像一个磁盘或光盘一样使用。在使用之前，一个 loop 设备必须要和一个文件进行连接。这种结合方式给用户提供了一个替代块特殊文件的接口。因此，如果这个文件包含有一个完整的文件系统，那么这个文件就可以像一个磁盘设备一样被 mount 起来。之所以叫loop设备（回环），其实是从文件系统这一层来考虑的，因为这种被 mount 起来的镜像文件它本身也包含有文件系统，通过loop设备把它mount起来，它就像是文件系统之上再绕了一圈的文件系统，所以称为 loop。

2. loop设备的使用

一般在linux中会有8个loop设备，一般是/dev/loop0~loop7，可用通过losetup -a查看所有的loop设备，如果命令没有输出就说明所有的loop设备都没有被占用，你可以按照以下步骤创建自己的loop设备。

1）创建一个文件
dd if=/dev/zero of=/var/loop.img bs=1M count=10240

2）使用losetup将文件转化为块设备
losetup /dev/loop0 /var/loop.img

3）通过lsblk查看刚刚创建的块设备
lsblk |grep loop0
losetup -a

4）当然，你也可以将这个块设备格式化并创建其他的文件系统，然后再mount到某个目录，有点多余啊，一般人不这么干。

5）要删除这个loop设备可以执行以下命令
losetup -d /dev/loop0

