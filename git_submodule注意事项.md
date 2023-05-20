# 定义
    git submodule 允许用户将一个 Git 仓库作为另一个 Git 仓库的子目录。 它能让你将另一个仓库克隆到自己的项目中，同时还保持提交的独立性

# 作用
    在我这里，它的作用非常明确，即给在各个项目中都会用到的代码段一个公共栖息地，做到“一处改，处处改”。


# 常用命令

## 添加
    git submodule add
    # 直接clone，会在当前目录生成一个someSubmodule目录存放仓库内容
    git submodule add https://github.com/miracleyoo/someSubmodule
    # 指定文件目录
    git submodule add https://github.com/miracleyoo/someSubmodule  src/submodulePath

    添加完之后，子模块目录可能是空的（似乎新版不会了），此时需要执行：
    git submodule update --init --recursive
    真正将子模块中的内容clone下来。同时，如果你的主目录在其他机器也有了一份clone，
    它们也需要执行上面的命令来把远端关于子模块的更改实际应用

    ***添加后的子模块,还需要到主模块进行add和commit,才能被记录***

## Clone时子模块初始化
    clone父仓库的时候加上--recursive，会自动初始化并更新仓库中的每一个子模块
    git clone --recursive
    或：
    如果已经正常的clone了，那也可以做以下补救：
    git submodule init
    git submodule update
    正常clone包含子模块的函数之后，由于.submodule文件的存在someSubmodule已经自动生成，但是里面是空的。上面的两条命令分别：
    1. 初始化的本地配置文件
    2. 从该项目中抓取所有数据并检出到主项目中。

## 更新
    git submodule update --remote
    Git 将会进入所有子模块，分别抓取并更新，默认更新master分支。
    不带--remote的update只会在本地没有子模块或它是空的的时候才会有效果。 

## 推送子模块修改
    这里有一个概念，就是主repo中的子模块被拉到本地时默认是一个子模块远程仓库master分支的detached branch。
    这个分支是master的拷贝，但它不会被推送到远端。如果在子模块中做了修改，并且已经add，commit，
    那你会发现当你想要push的时候会报错：Updates were rejected because a pushed branch tip is behind its remote。
    这便是所谓的detached branch的最直接的体现
    解决方法是：在子模块中先git checkout master，然后在git merge <detached branch name/number>，
    最后git push -u origin master即可。


# ***注意点***
    子模块修改提交之后，一定要回去主项目添加子模块的修改，
    其实，就是告诉主项目使用更新后的子模块，然后再将修改提交到远程。
    这样，主项目中对子模块的引用才会更新，要不然，你会神奇的发现，你主项目只要git submodule update就会回到没有修改的版本。
    记住两点：
    子模块是另一个仓库。 
    更新子模块不会自动更新主模块的引用！





