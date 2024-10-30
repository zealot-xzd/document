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

function log_msg() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $@"
}

function create_ramdisk() {
   # 创建Ramdisk
 if [ ! -e $MOUNT_PATH ]; then
     log_msg "Create ramdisk..." > $LOG

     RAMDISK_SECTORS=$(($DISK_SPACE/512))
     DISK_ID=$(hdiutil attach -nomount ram://$RAMDISK_SECTORS | tr -d [:space:])
     log_msg "Disk device ID is: $DISK_ID, ret=$?" | tee -a $LOG

     newfs_hfs -v 'Ramdisk' ${DISK_ID}
     log_msg "Create hfs+ file system on $DISK_ID : ret=$?" | tee -a $LOG

     mkdir -p ${MOUNT_PATH}
     mount -o rw,noatime,nobrowse -t hfs ${DISK_ID} ${MOUNT_PATH}
     log_msg "mount $DISK_ID to ${MOUNT_PATH}, ret=$?" | tee -a $LOG

     chown root:wheel ${MOUNT_PATH}
     log_msg "chown root:wheel ${MOUNT_PATH}" | tee -a $LOG

     chmod 1777 ${MOUNT_PATH}
     log_msg "set sticky bit: ${MOUNT_PATH}" | tee -a $LOG

     log_msg "Create ramdisk finish" | tee -a $LOG
 elif [[ $1 == "umount" ]]; then
     hdiutil detach $MOUNT_PATH || umount -f $MOUNT_PATH
     log_msg "Delete/unmount ramdisk $MOUNT_PATH, ret=$?"
     exit
 fi
}

create_ramdisk

