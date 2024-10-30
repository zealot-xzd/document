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

## 恢复备份
#if [ -s $BAK_PATH ]; then
#    echo "["`date`"]" "Restoring BAK Files ..." | tee -a $LOG
#    tar -zxvf $BAK_PATH -C $MOUNT_PATH 2>&1 | tee -a $LOG
#fi

function log_msg() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $@"
}

# 设置要创建的文件夹
Dirs=(
"$MOUNT_PATH/$USER/Caches/Microsoft Edge"
"$MOUNT_PATH/$USER/Caches/com.apple.Safari"
"$MOUNT_PATH/$USER/Caches/Xcode"
"$MOUNT_PATH/$USER/Caches/NeteaseMusic"
"$MOUNT_PATH/$USER/downloads"
"$MOUNT_PATH/$USER/tmp"
)
# 如果文件夹不存在，则创建相应的文件夹
for Dir in "${Dirs[@]}"; do
    if [ ! -d "$Dir" ]; then
        log_msg "Making Directory: $Dir" | tee -a $LOG
        mkdir -p "$Dir"
    fi
done

Links=(
"$HOME/Library/Caches/Microsoft Edge"
"$HOME/Library/Caches/com.apple.Safari"
)
# 如果链接不存在，则创建相应的软连接
for Link in "${Links[@]}"; do
    if [ ! -d "$Link" ]; then
        log_msg "Making Directory: $Link" | tee -a $LOG
        mkdir -p "$Link"
    fi

    Dir_Name=${Link#*Library/Caches/}
    if [ ! -L "$Link" ]; then
        if [ -d "$Link" ]; then
            mv -v "$Link/*" "$MOUNT_PATH/$USER/Caches/$Dir_Name/" | tee -a $LOG
            log_msg "\nMove $Link to $MOUNT_PATH/$USER/Caches/$Dir_Name/" | tee -a $LOG

            rm -rfv "$Link" | tee -a $LOG
            log_msg "\nDelete $Link" | tee -a $LOG
        fi
        ln -sv "$MOUNT_PATH/$USER/Caches/$Dir_Name" "$Link" | tee -a $LOG
        echo "\nCreate soft link: $LINK" | tee -a $LOG
    fi
done

