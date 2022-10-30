#!/system/bin/sh

source check_data_mount.sh
log_to_data_partition=`is_ext4_f2fs_data_partition`
log_file="kernel.log"

kernel_log_prop=`getprop persist.vendor.lge.service.kernel.enable`
log_size_prop=`getprop persist.product.lge.service.logsize.setting`
#vold_prop=`getprop vold.decrypt`
#vold_propress=`getprop vold.encrypt_progress`
bootmode_prop=`getprop ro.bootmode`
crypto_type_prop=`getprop ro.crypto.type`


ro_build_ab_update=`getprop ro.build.ab_update`
if [ "$ro_build_ab_update" = "true" ]; then
tmp_log_path="mnt/product/els"
else
tmp_log_path="cache"
fi


touch /data/logger/${log_file}
chmod 0644 /data/logger/${log_file}


storage_low_prop=`getprop persist.product.lge.service.logger.low`

file_size=8388608
file_cnt=0


if [[ $log_size_prop > 0 ]]; then
   file_size=`expr $log_size_prop \* 1024`
fi

if [ "$storage_low_prop" = "1" ]; then
   file_size=1048576
fi

case "$kernel_log_prop" in
    6)
        file_size=1048576
        file_cnt=5
        ;;
    5)
        file_cnt=100
        ;;
    4)
        file_cnt=50
        ;;
    3)
        file_cnt=20
        ;;
    2)
        file_cnt=10
        ;;
    1)
        file_cnt=5
        ;;
    0)
        file_cnt=0
        ;;
    *)
        file_cnt=0
        ;;
esac

if [[ $file_cnt > 0 ]]; then
    if [[ $log_to_data_partition == 1 ]]; then
        if [ -s "/data/logger/bootloader_log" ]; then
            move_log "/data/logger/${log_file}" "/data/logger/bootloader_log"
        fi
        move_log "/data/logger/${log_file}" "/${tmp_log_path}/encryption_log/${log_file}"

        /system/bin/kernel_logger -f /data/logger/${log_file} -s $file_size -m $file_cnt
    else
        touch /${tmp_log_path}/encryption_log/${log_file}
        chmod 0644 /${tmp_log_path}/encryption_log/${log_file}
        /system/bin/kernel_logger -f /${tmp_log_path}/encryption_log/${log_file} -s $file_size -m $file_cnt
    fi
else
    rm -rf /${tmp_log_path}/encryption_log/${log_file}*
fi
