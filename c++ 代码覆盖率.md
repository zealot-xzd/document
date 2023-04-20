# c/c++ 代码覆盖率

## 介绍

    gcov是一个测试代码覆盖率的工具。它必须与GCC一起使用来分析程序，以帮助并发现程序的未测试部分，还可以结合lcov工具生成html格式的统计报告，可以方便的查看代码覆盖率的情况，甚至可以查看每一行代码的执行次数。

## 原理

    基本块BB：如果一段程序的第一条语句被执行过一次，这段程序中的每一条语句都要执行一次，那么这段程序构成一个基本块。一个BB中的所有语句的执行次数一定相同。一般情况下BB的最后一条语句一定是一个跳转语句，跳转的目的地是另外一个BB的第一条语句，如果跳转是有条件的，就产生了分支，该BB就有两个BB作为目的地。

    跳转ARC：从一个BB到另外一个BB的跳转叫做一个跳转arc，要想知道程序中的每条语句和分支的执行次数，就必须知道每个BB和ARC的执行次数。

    如果把BB作为节点，ARC作为边，那么一个函数中的所有BB就构成了一个有向图（流程图）。

    为了统计BB和ARC的执行次数，GCC会在产生汇编文件时进行插桩。在程序执行的过程中，这些桩代码负责收集程序的执行信息。根据节点的入度和出度相等这个基本原理，只要知道了部分ARC的执行次数，就可以推断所有BB和ARC的执行次数。所以不会对所有的ARC插桩，只需要最低限度的插桩。

    编译时为每个.c文件生成对应的.gcno文件，存储流程图信息。运行程序时，为每个.c文件生成.gcda文件，收集代码覆盖率数据。

## 使用

    Linux下的工具gcov（gcc自带）可以统计函数覆盖、行覆盖、条件覆盖、分支覆盖。Gcov只能和gcc一起使用。
    
    多次执行一个进程，gcda文件里的数据会累加。

    多个实例同时运行，gcda文件中的数据也可以正确更新。

### 使用举例

    gcc -fprofile-arcs -ftest-coverage -o test test.c

    编译时，每个.c源文件都会生成.gcno文件。执行可执行文件时，每一个源文件都会生成.gcda文件
    gcno文件包含重构流程图的信息，并且记录BB的源代码行号。.gcda文件包含arc转换的计数，还有一些汇总信息
    .so动态库的代码覆盖率不进行统计。
    
    
### 操作要点：

    1、开发人员编译程序，程序代码中已经处理了sigterm信号，正常退出，在其中加上__gcov_flush()。

    2、将可执行文件和所有.c文件对应的.gcno文件发送给测试人员。

    3、测试人员执行程序的自动化用例（这里只执行了高优先级的测试用例）。

    4、所有.c文件都生成了对应的.gcda文件。

    5、测试人员使用lcov生成html统计报告。有整体和每个文件的统计数据，包括行、分支和函数覆盖率。如果要看每行、每个分支、每个函数的执行次数，需要源代码。

### 补充说明

    1.gcc自带gcov，所以不需要单独安装。

    2.使用gcov需要在gcc编译时加上参数gcc -fprofile-arcs -ftest-coverage，编译后每一个.c文件都会产生一个.gcno的文件。

    3.运行使用gcov选项编译出的可执行文件，程序正常退出后，每一个.c文件都会产生.gcda格式的文件，
    该文件记录了代码执行的覆盖率情况。如果想分析代码或者想查看某个.c文件里每一行的执行情况，
    在有源码情况下，可以使用gcov -b 文件名生成.c.gcov文件，里面可以查看每一行代码的执行情况。
    如果运行的是一个守护进程，则需要开发人员在代码中主动调用 exit 或 __gcov_flush函数输出统计结果。
    还可以拦截杀死进程的信号，在杀死进程前调用__gcov_flush()输出数据，这样手动杀死守护进程即可得到.gcda数据文件。

    
``` bash 
#!/bin/sh
SERVER_NAME=$1

pid=`ps -ef | grep $SERVER_NAME | grep -v "grep" | awk '{print $2}'`
echo $pid
gdb -q attach $pid <<__EOF__
p __gcov_flush()
__EOF__
``` 

    4.程序运行测试完成后，每一个.c文件都有一个对应的.gcda文件，路径与编译程序的机器上项目代码的绝对路径一致，
    去同样的路径下找即可。如果想指定目录，可使用下面两个环境变量重定位数据文件：

    export GCOV_PREFIX - 指定加入到目标文件中的绝对路径前缀，默认没有前缀，生成的.gcda路径与目标文件一致
    export GCOV_PREFIX_STRIP - 指示要跳过的目录(指的是编译时目标文件的绝对路径)层次

    比如编译后目标文件在‘/user/build/src/foo.o’，编译后的程序执行时会创建‘/user/build/src/foo.gcda’文件。
    但若把程序拷贝到另一个系统中运行时，可能并没有这个目录，此时设置环境变量

    export GCOV_PREFIX=/target/run
    export GCOV_PREFIX_STRIP=1

    这样，运行时将输出到‘/target/run/build/src/foo.gcda’文件。然后可把生成的所有.gcda文件拷贝到本机编译时的代码目录中
    使用gcov工具即可。

    5.测试人员自己在没有源码时，借助lcov也可以生成代码覆盖率统计情况。lcov工具需要安装，
    下载后直接make install即可。首先拿到开发编译后生成的.o文件和.gcno文件，再把程序运行后产生的gcda文件放到同一个目录下，

    使用命令
    lcov -c -d . -o output.info 
    -c表示要捕获覆盖率数据，
    -d表示 使用从gcda文件中捕获数据，后面接路径，
    -o 表示生成的结果保存的文件。

    可使用
    lcov -l output.info查看代码覆盖率统计信息。
    注意：lcov默认不统计branch的统计信息，需要加上参数--rc lcov_branch_coverage=1。才能统计到branch的信息。
    得到info文件后就可以生成html的结果统计了，
    genhtml -o result output.info --branch-coverage --rc lcov_branch_coverage=1 --no-source，
    -o表示生成的html结果保存到那个目录下
    -branch-coverage --rc lcov_branch_coverage=1 --no-source表示要生成的html要包含branch的信息，
    --no-source表示没有源码时生成报告，如果不加该参数，目录下没有.c文件源码则不能生成html结果报告。

### 实际操作情况：

    1.开发人员在程序代码里处理sigterm信号时，调用__gcov_flush()输出数据文件，这样再杀死进程后就可以得到数据文件，
    开发人员使用gcc编译时加上参数-fprofile-arcs -ftest-coverage。

    2.把带gcov选项编译好的文件，放到测试环境运行。

    3.新的进程启动后，执行测试用例或者自动化测试，在相应的目录下会生成gcda文件，让程序正常退出或者调用__gcov_flush()

    4.上面生成的gcda文件和开发编译后的.o以及.gcno文件copy到安装了gcc和lcov的linux PC中，
    每个.gcda,.o,.gcno文件都是一一对应的，目录结构也一致。

    5.使用lcov -c -d . -o output.info --rc lcov_branch_coverage=1将.gcno, .gcda文件合成一个.info文件。
    可使用lcov -l output.info查看该info文件的概况，包含每个.c文件的覆盖率百分比信息。
    再使用genhtml output.info -o result --branch-coverage --rc lcov_branch_coverage=1 --no-source
    即可生成html，在result目录下即可看到结果，里面记录了程序本次运行过程中代码的覆盖情况。

    6.多次测试、多台设备或者多个人的测试覆盖数据可以合并。
    参考第3,4,5步骤将多次或多人执行的gcda文件分别生成info文件。然后使用下面的命令合并info文件。

    lcov -a output1.info -a output2.info -o sum.info -rc lcov_branch_coverage=1，
    -a表示要合并的info文件，-rc lcov_branch_coverage=1表示统计branch,注意该参数必须加上，
    否则会导致统计branch的覆盖率的数据有遗漏和错误。然后参考步骤5使用sum.info生成合并后的报告。

    7.如果想要忽略某些目录，或者.c文件的覆盖，比如想忽略abc_xxx.c的覆盖率，
    可使用lcov -r sum.info '*/abc_xxx.c'-o newdata.info,-r参数后可以匹配正则，
    新生成的newdata.info中将不再包含ospf_xxx的信息，再使用步骤5生成html报告，里面将不再含有ospf_xxx.c的覆盖率信息。