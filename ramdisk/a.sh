MOUNT_PATH="/Volumes/ramdisk"
Dirs=(
"$MOUNT_PATH/Caches/Microsoft Edge"
"$MOUNT_PATH/Caches/com.apple.Safari"
"$MOUNT_PATH/Caches/Xcode"
"$MOUNT_PATH/Caches/NeteaseMusic"
"$MOUNT_PATH/downloads"
)

#for Dir in $Dirs; do
for Dir in "${Dirs[@]}"; do
    if [ ! -d "$Dir" ]; then
        echo "["`date`"]" "Making Directory: $Dir" | tee -a $LOG
        #mkdir -p "$Dir"
    else
        echo "exist Directory: $Dir" | tee -a $LOG

    fi
done
