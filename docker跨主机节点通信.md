# host1创建swarm集群

[root@102122190 zhidong]# docker swarm init --advertise-addr 10.212.21.90
Swarm initialized: current node (rsmbtirt9pbirje6whov5ljfh) is now a manager.

To add a worker to this swarm, run the following command:

    docker swarm join --token SWMTKN-1-4uhdczclykyrriid5diwkfa21vsrlj6znzrecqnxjoua1qlz38-42noqp8f0ke5gpfaa06g2t5u7 10.212.21.90:2377

To add a manager to this swarm, run 'docker swarm join-token manager' and follow the instructions.

# 获取join-token
docker swarm join-token worker/manager

# host2加入swarm
root@Kylin:~# docker swarm join --token SWMTKN-1-4uhdczclykyrriid5diwkfa21vsrlj6znzrecqnxjoua1qlz38-42noqp8f0ke5gpfaa06g2t5u7 10.212.21.90:2377
This node joined a swarm as a worker.


# host1创建overlay网络
[root@102122190 ~]# docker network create --driver=overlay --attachable test-net
12hm7z4onwjbm7f51a42t919h
创建网络可以指定参数：
$ docker network create \
  --driver overlay \
  --ingress \
  --subnet=10.11.0.0/16 \
  --gateway=10.11.0.2 \


# host1运行容器（可以指定ip）
[root@102122190 ~]# docker run --rm --name test -it --network test-net mirrors.sangfor.org/centos /bin/bash


# host2运行容器（可以指定ip）
root@Kylin:~# docker run  --name test2 -itd --network test-net centos /bin/bash
81b0192c59f2c4d64a9538dbe3130d15b4c7f3baf14184b8c4ee48a2e018e1a8

# 容器内互相ping对方，是互通的
