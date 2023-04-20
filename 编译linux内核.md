# Kconfig选项
depends 表示该选项仅在满足其先决条件（其背后的布尔构造）的情况下才会显示在菜单中。
select表示当用户选择此选项时，作为参数给出的选项select将被自动选择

# 单独设置配置项
The kernel has a tool (./scripts/config) to change specific options on .config. Here is an example:
./scripts/config --set-val CONFIG_OPTION y
Although, it doesn't check the validity of the .config file.

# 升级内核，迁移配置
cp /user/some/old.config .config
make oldconfig 或者make olddefconfig

# 合并配置
scripts/kconfig/merge_config.sh
$ cd linux
$ git checkout v4.9
$ make x86_64_defconfig
$ grep -E 'CONFIG_(DEBUG_INFO|GDB_SCRIPTS)[= ]' .config
# CONFIG_DEBUG_INFO is not set
$ # GDB_SCRIPTS depends on CONFIG_DEBUG_INFO in lib/Kconfig.debug.
$ cat <<EOF >.config-fragment
> CONFIG_DEBUG_INFO=y
> CONFIG_GDB_SCRIPTS=y
> EOF
$ # Order is important here. Must be first base config, then fragment.
$ ./scripts/kconfig/merge_config.sh .config .config-fragment
$ grep -E 'CONFIG_(DEBUG_INFO|GDB_SCRIPTS)[= ]' .config
CONFIG_DEBUG_INFO=y
CONFIG_GDB_SCRIPTS=y

merge_config.sh is a simple front-end for the make alldefconfig target.

When cross compiling, ARCH must be exported when you run merge_config.sh, e.g.:

export ARCH=arm64
export CROSS_COMPILE=aarch64-linux-gnu-
make defconfig
./scripts/kconfig/merge_config.sh .config .config-fragment

# 查看新内核配置相对于旧内核配置的区别
方法一：
cp user/some/old.config .config
make listnewconfig

方法二： 比较粗糙，不推荐使用
make oldconfig
scripts/diffconfig .config.old .config | less

# 环境变量
KCONFIG_CONFIG
指定新的内核配置文件名，替换默认的.config

KCONFIG_ALLCONFIG： 对{allyes/allmod/allno/rand}config目标
设置自定义的配置项
KCONFIG_ALLCONFIG=custom-notebook.config make allnoconfig/allyesconfig/allmodconfig
KCONFIG_ALLCONFIG=mini.config make allnoconfig
make KCONFIG_ALLCONFIG=mini.config allnoconfig
