# centos7 systemctl status servicename执行慢的问题

一，这个问题和systemd-journald有关，故我们先简单了解下：

    过去只有 rsyslogd 的年代中，由于 rsyslogd 必须要开机完成并且执行了 rsyslogd 这个 daemon 之后，登录文件才会开始记录。所以，核心还得要自己产生一个 klogd 的服务， 才能将系统在开机过程、启动服务的过程中的信息记录下来，然后等 rsyslogd 启动后才传送给它来处理。

    现在有了 systemd 之后，systemd 使用systemd-journald统一管理所有 Unit 的启动日志。由于systemd是kernel唤醒的，然后又是第一个执行的软件，它可以主动调用 systemd-journald 来协助记载登录信息。因此在开机过程中的所有信息，包括启动服务与服务若启动失败的情况等等，都可以直接被记录到 systemd-journald 里头去！

    不过 systemd-journald 由于是使用于内存的登录文件记录方式，因此重新开机过后，开机前的登录文件信息当然就不会被记载了。 为此，我们还是建议启动 rsyslogd 来协助分类记录！也就是说， systemd-journald 用来管理与查询这次开机后的登录信息，而 rsyslogd 可以用来记录以前及现在的所以数据到磁盘文件中，方便未来进行查询！


二，问题场景：

一台centos7系统有load高的报警，故登录上去查看，发现系统很卡，系统磁盘io吃的比较多。之后，发现很多systemctl status的进程，并且这种进程占用系统io很多。  


问题分析定位：

1，centos7的bug

2，systemctl的问题  


三，解决过程：

1，centos7已经用了很长时间，目前处于稳定，并且翻看centos7的bug list未发现有类似异常。故排除了系统bug。

2，开始查找systemctl的问题，果不其然发现是systemd-journald的问题。

1）strace命令查看问题，发现是读取systemd-journald日志比较慢

#strace -s 1024 systemctl status nginx


2）查看status输出：

#systemctl status nginx

● nginx.service - nginx - high performance web server

   Loaded: loaded (/usr/lib/systemd/system/nginx.service; disabled; vendor preset: disabled)

   Active: active (running) since 一 2018-01-08 18:25:37 CST; 2h 20min ago

     Docs: http://nginx.org/en/docs/

 Main PID: 22403 (nginx)

   CGroup: /system.slice/nginx.service

           ├─22403 nginx: master process /usr/sbin/nginx -c /etc/nginx/nginx.conf

           ├─22404 nginx: worker process

           ├─22405 nginx: worker process

           ├─22408 nginx: worker process


1月 08 18:25:37 test systemd[1]: Starting nginx - high performance web server...

1月 08 18:25:37 test nginx[22398]: nginx: the configuration file /etc/nginx/nginx.conf syntax is ok

1月 08 18:25:37 test nginx[22398]: nginx: configuration file /etc/nginx/nginx.conf test is successful

1月 08 18:25:37 test systemd[1]: Started nginx - high performance web server.


可以看到systemctl有的输出有nginx启动时候相关的信息。而这些输出是从systemd-journald中读取的。


3）systemd-journald的日志默认是存储在/run/log/journal目录，发现这个目录已经有4G了。查看网上相关资料，发现也有其它人遇见过类似的问题。可以通过修改systemd-journald的配置来解决问题：

#vim /etc/systemd/journald.conf

SystemMaxUse=100M

RuntimeMaxUse=100M

###

SystemMaxUse= 与 RuntimeMaxUse= 限制全部日志文件加在一起最多可以占用多少空间。而SystemMaxUse= 与 RuntimeMaxUse= 的默认值是10%空间与4G空间两者中的较小者，故把这两个配置调小了。


重启systemd-journald：

#systemctl restart systemd-journald


4）操作完成之后发现系统load慢慢降了下来，systemctl status命令也变快了。


四，结论：

1，通过限制systemd-journald日志的大小来解决这个问题。副作用是保存的日志变少，但是可接受，目前没有发现有异常