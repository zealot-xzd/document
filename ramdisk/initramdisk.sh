#!/usr/bin/env sh
set -x

# 设置内存盘的名称
DISK_NAME=ramdisk
MOUNT_PATH=/Volumes/$DISK_NAME

# 设置备份文件的保存路径
LOG_PATH=$HOME/Library/Logs/ramdisk
[[ -d $LOG_PATH ]] || mkdir -p $LOG_PATH
BAK_PATH=$LOG_PATH/$DISK_NAME.tar.gz

# 设置ramdisk日志文件
LOG=$LOG_PATH/init_ramdisk_log.txt

# 设置分配给内存盘的空间大小(MB) 这是上限值，一般情况下使用多少占多少的内存
DISK_SPACE=1024

# The RAM amount you want to allocate for RAM disk. One of
# 1024 2048 3072 4096 5120 6144 7168 8192
# By default will use 1/8 of your RAM

DISK_SPACE=$(sysctl hw.memsize | awk '{print $2;}')
DISK_SPACE=$(($DISK_SPACE/8))

# 创建Ramdisk
if [ ! -e $MOUNT_PATH ]; then
    echo "["`date`"]" "Create ramdisk..." > $LOG
    RAMDISK_SECTORS=$(($DISK_SPACE/512))
    DISK_ID=$(hdiutil attach -nomount ram://$RAMDISK_SECTORS)
    echo "["`date`"]" "Disk ID is :" $DISK_ID | tee -a $LOG
    diskutil erasevolume HFS+ $DISK_NAME ${DISK_ID} | tee -a $LOG
elif [[ $1 == "umount" ]]; then
    echo "Delete/unmount ramdisk $MOUNT_PATH"
    hdiutil detach $MOUNT_PATH || umount -f $MOUNT_PATH
    exit
fi

# 隐藏分区
chflags hidden $MOUNT_PATH

## 恢复备份
#if [ -s $BAK_PATH ]; then
#    echo "["`date`"]" "Restoring BAK Files ..." | tee -a $LOG
#    tar -zxvf $BAK_PATH -C $MOUNT_PATH 2>&1 | tee -a $LOG
#fi

# 设置要创建的文件夹
Dirs=(
"$MOUNT_PATH/Caches/Microsoft Edge"
"$MOUNT_PATH/Caches/com.apple.Safari"
"$MOUNT_PATH/Caches/Xcode"
"$MOUNT_PATH/Caches/NeteaseMusic"
"$MOUNT_PATH/downloads"
)
# 如果文件夹不存在，则创建相应的文件夹
for Dir in "${Dirs[@]}"; do
    if [ ! -d "$Dir" ]; then
        echo "["`date`"]" "Making Directory: $Dir" | tee -a $LOG
        mkdir -p "$Dir"
    fi
done


Links=(
"$HOME/Library/Caches/Microsoft Edge"
"$HOME/Library/Caches/com.apple.Safari"
)
# 如果链接不存在，则创建相应的软连接
for Link in "${Links[@]}"; do
    Dir_Name=${Link##*/}
    if [ ! -L "$Link" ]; then
        if [ -d "$Link" ]; then
            echo "\nMove & Delete Dir: $Dir_Name" | tee -a $LOG
            mv -v "$Link/*" "$MOUNT_PATH/Caches/$Dir_Name/" | tee -a $LOG
            rm -rfv "$Link" | tee -a $LOG
        fi
    echo "\nCreate soft link: $LINK" | tee -a $LOG
    ln -sv "$MOUNT_PATH/Caches/$Dir_Name" "$Link" | tee -a $LOG
    fi
done

