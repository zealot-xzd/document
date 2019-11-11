Linux中 date 时间和 hwclock时间不一致解决方案

1. 必须确保时区准确，否则时间同步后显示不正常

[root@102122190 zhidong]# date -R
Mon, 11 Nov 2019 16:30:59 +0800

[root@102122190 zhidong]# date
2019年 11月 11日 星期一 16:31:20 CST


2. 如果时区不正确，如，在中国，时区是CTS，若不是，修改方式：

执行命令： tzselect  按提示操作

3. 将时区信息拷贝，并覆盖原来的时区信息，操作命令：
[root@102122190 zhidong]# cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime

4. 操作系统有两个时间： 软件时间和硬件时间
软件时间： 查看方式 date，是是距离1970.1.1的时间差；

硬件时间： sudo hwclock -r，硬件时间是BIOS的时间。

                    -w : 将软件时间写入到硬件时间；

                    -r   : 读取硬件时间。

查看并同步软件时间和硬件时间：

执行命令： sudo hwclock -w; hwclock -r ; date

或者 sudo hwclock --systohc
